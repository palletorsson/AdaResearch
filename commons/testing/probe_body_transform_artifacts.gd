extends SceneTree

## DO THE THREE BODY-OPERATED TRANSFORMATIONS ACTUALLY BITE, AND ONLY FOR US?
##
## 2026-09-08, Palle: "In the transformation sequence. Three new artifacts …
## Collider movement space. A cube grid and when we walk it space is created by
## removing what our collider touches. On the same theme a wall mech that is
## closed but open when we approach. The same with scaling scale down around us
## so we can walk."
##
## All three answer the visitor's BODY rather than a switch, which makes them the
## easiest artifacts in the corpus to ship dead: an Area3D whose mask omits a
## layer, or an acceptance test that never says yes, and the thing stands there
## looking finished and does nothing at all. There is no error to notice. So this
## probe asserts the bite in both directions.
##
## THE POSITIVE: a body shaped exactly like the endless museum's Walker — a bare
## CharacterBody3D on collision layer 1, in group `em_walker` and nothing else,
## which is in NO grid player group, has no XROrigin3D above it and is not on
## layer 20 — must carve the lattice, open the wall and shrink the field. That is
## the body an artifact masking only PLAYER_LAYER cannot see, and the museum is
## where these will mostly be met.
##
## THE NEGATIVE, WHICH IS THE POINT: an "imposter" — a CharacterBody3D on the same
## layer 1, in no group and under no XROrigin3D — must change NOTHING. That is a
## hazard creature: `hazard_creature_base` extends CharacterBody3D, so the obvious
## acceptance test (`body is CharacterBody3D`) hands all three artifacts to the
## museum's own traffic. A silhouette would cut the tunnel, hold the wall open and
## keep the field small, and a visitor arriving afterwards would meet a room that
## had already been transformed by somebody else — which is the one thing these
## three must never be. Without this half the probe passes on an artifact that
## says yes to everything.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_body_transform_artifacts.gd

const CARVE := "res://commons/artifacts/carve_grid/carve_grid.tscn"
const WALL := "res://commons/artifacts/approach_wall/approach_wall.tscn"
const SCALE := "res://commons/artifacts/approach_scale/approach_scale.tscn"
const REPORT := "res://ada_run/body_transform_probe.txt"

## Far enough apart that no artifact's field can see another's visitor.
const AT_CARVE := Vector3(0, 0, 0)
const AT_WALL := Vector3(40, 0, 0)
const AT_SCALE := Vector3(80, 0, 0)

var _lines: Array[String] = []
var _fails: Array[String] = []
var _carve: Node3D
var _wall: Node3D
var _scale: Node3D
var _walker: CharacterBody3D
var _imposter: CharacterBody3D
## PEAKS, TAKEN WHILE THE BODY IS STILL THERE. The first version of this file read
## openness AFTER _walk had finished, by which time the walker had moved on to the
## next artifact and the wall had correctly closed behind it: a wall doing exactly
## its job, reported as "the wall did not open". Both of these ease back to rest in
## well under a second, so an artifact that answers the body can only be measured
## while the body is answering it.
var _pk_open := 0.0
var _pk_gap := 0.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node3D.new()
	root.name = "Field"
	get_root().add_child(root)

	_carve = _stand(root, CARVE, AT_CARVE, "Carve")
	_wall = _stand(root, WALL, AT_WALL, "Wall")
	_scale = _stand(root, SCALE, AT_SCALE, "Scale")
	if _carve == null or _wall == null or _scale == null:
		_finish()
		return

	# THE WALKER, built to the museum's own recipe (endless_museum.gd:3386-3396):
	# a bare CharacterBody3D, layer 1, group em_walker, nothing else.
	_walker = _body(root, "Walker", true)
	# THE IMPOSTER: identical in every way a physics query can see, and not a
	# visitor. This is a hazard creature.
	_imposter = _body(root, "Imposter", false)
	_park(_walker)
	_park(_imposter)
	await _settle(8)

	# ── at rest ───────────────────────────────────────────────────────
	var rest_carved: float = float(_carve.call("carved_fraction"))
	var rest_open: float = float(_wall.call("openness"))
	var rest_gap: float = float(_scale.call("narrowest_gap_m"))
	_say("AT REST   carved=%.3f  wall_open=%.3f  narrowest_gap=%.2f m" % [rest_carved, rest_open, rest_gap])
	_check(rest_carved < 0.001, "  the lattice is whole: %.3f carved" % rest_carved,
		"the lattice carved itself with nobody in the room — it is seeing its own StaticBody3D on layer 1")
	_check(rest_open < 0.05, "  the wall is closed: openness %.3f" % rest_open,
		"the wall hangs open with nobody near it — closed must be the resting state")
	_check(_carve.call("live_count") > 0, "  the lattice has %d live cube(s)" % int(_carve.call("live_count")),
		"the lattice built nothing")

	# THE CAPTURE ANCHOR. A MultiMesh measures as a 1 m box, so every screenshot of
	# this artifact would be framed to a tenth of it. The anchor is a MeshInstance3D
	# with layers = 0 sized to the real extent; if it goes, the framing goes quietly.
	_check(_has_anchor(_carve), "  the lattice carries a layers=0 AABB anchor",
		"no layers=0 MeshInstance3D anchor — the capture pipeline will frame a MultiMesh as a 1 m box")

	# ── THE NEGATIVE: a hazard creature walks the same route ──────────
	_pk_open = 0.0
	_pk_gap = 0.0
	await _walk(_imposter)
	var imp_carved: float = float(_carve.call("carved_fraction"))
	var imp_open: float = _pk_open
	var imp_gap: float = _pk_gap
	_say("IMPOSTER  carved=%.3f  wall_open=%.3f  narrowest_gap=%.2f m" % [imp_carved, imp_open, imp_gap])
	_check(imp_carved <= rest_carved + 0.001, "  it carved nothing: %.3f" % imp_carved,
		"a hazard creature cut the tunnel — the acceptance test takes any CharacterBody3D")
	_check(imp_open <= rest_open + 0.05, "  the wall stayed shut: %.3f" % imp_open,
		"a hazard creature opened the wall — the acceptance test takes any CharacterBody3D")
	_check(imp_gap <= rest_gap + 0.02, "  the field stayed big: %.2f m" % imp_gap,
		"a hazard creature shrank the field — the acceptance test takes any CharacterBody3D")
	_park(_imposter)
	await _settle(10)

	# ── THE POSITIVE: the museum's walker walks the same route ────────
	_pk_open = 0.0
	_pk_gap = 0.0
	await _walk(_walker)
	var w_carved: float = float(_carve.call("carved_fraction"))
	var w_open: float = _pk_open
	var w_gap: float = _pk_gap
	_say("WALKER    carved=%.3f  wall_open=%.3f  narrowest_gap=%.2f m" % [w_carved, w_open, w_gap])
	_check(w_carved > 0.001, "  it cut a tunnel: %.3f of the lattice gone" % w_carved,
		"the walker carved NOTHING — either the area does not mask layer 1, or bite_m cannot reach past the contact surface")
	_check(w_open > 0.35, "  the wall made way: openness %.3f" % w_open,
		"the wall did not open for the museum's walker")
	_check(w_gap > rest_gap + 0.05, "  the field shrank: gap %.2f -> %.2f m" % [rest_gap, w_gap],
		"the blocks did not shrink for the museum's walker")

	# ── leaving ───────────────────────────────────────────────────────
	_park(_walker)
	await _settle(30)
	var gone_carved: float = float(_carve.call("carved_fraction"))
	var gone_open: float = float(_wall.call("openness"))
	var gone_gap: float = float(_scale.call("narrowest_gap_m"))
	_say("LEFT      carved=%.3f  wall_open=%.3f  narrowest_gap=%.2f m" % [gone_carved, gone_open, gone_gap])
	_check(gone_open < 0.15, "  the wall closed again: %.3f" % gone_open,
		"the wall stayed open after the visitor left — it is a door, not a wall")
	_check(gone_gap < rest_gap + 0.05, "  the blocks grew back: %.2f m" % gone_gap,
		"the field stayed open after the visitor left")
	# The tunnel is the one thing that must NOT heal: regrow_s is 0 by default
	# because the corridor is the record of the passage.
	_check(abs(gone_carved - w_carved) < 0.001, "  the tunnel stayed cut: %.3f" % gone_carved,
		"the tunnel healed itself — regrow_s should default to 0, the corridor is the record")

	_finish()


# ── the field ─────────────────────────────────────────────────────────────

func _stand(root: Node3D, path: String, at: Vector3, what: String) -> Node3D:
	var ps: PackedScene = load(path) as PackedScene
	if ps == null:
		_check(false, "%s scene will not load" % what, "%s: %s did not load" % [what, path])
		return null
	var n: Node3D = ps.instantiate() as Node3D
	if n == null:
		_check(false, "%s root is not a Node3D" % what, "%s: root is not a Node3D" % what)
		return null
	root.add_child(n)
	n.global_position = at          # AFTER add_child — before it, the set is refused
	return n


## The museum's walker, or a creature wearing the same physics. The only
## difference the artifacts are allowed to notice is the group.
func _body(root: Node3D, name: String, visitor: bool) -> CharacterBody3D:
	var b := CharacterBody3D.new()
	b.name = name
	b.collision_layer = 1
	b.collision_mask = 0            # it walks through everything; we are testing detection, not physics
	if visitor:
		b.add_to_group("em_walker")
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.5
	cs.shape = cap
	cs.position = Vector3(0, 0.75, 0)
	b.add_child(cs)
	root.add_child(b)
	return b


## Out of every artifact's reach.
func _park(b: CharacterBody3D) -> void:
	b.global_position = Vector3(0, 0, 400)


## The same route past all three, so the two bodies are compared on identical
## ground. Teleported rather than driven: this measures who is SEEN, not walking.
func _walk(b: CharacterBody3D) -> void:
	for step in [
		AT_CARVE + Vector3(0, 0, -1.6), AT_CARVE + Vector3(0, 0, -0.8),
		AT_CARVE, AT_CARVE + Vector3(0, 0, 0.8), AT_CARVE + Vector3(0, 0, 1.6),
	]:
		b.global_position = step
		await _settle(4)
	# STANDING TIME, NOT A TOUCH. Both of these ease toward their target and both
	# rebuild their visitor list on a resync tick, so a dwell shorter than one tick
	# measures the probe's patience rather than the artifact. A second and a half is
	# what a visitor walking up to a wall actually spends in front of it; if the
	# wall needs longer than that it is broken whatever the number says.
	b.global_position = AT_WALL + Vector3(0, 0, -0.9)
	for i in range(9):
		await _settle(10)
		_pk_open = maxf(_pk_open, float(_wall.call("openness")))
	_say("    wall settles to openness %.3f with %d visitor(s)"
		% [_pk_open, int(_wall.call("visitor_count"))])
	b.global_position = AT_SCALE
	for i in range(9):
		await _settle(10)
		_pk_gap = maxf(_pk_gap, float(_scale.call("narrowest_gap_m")))
	_say("    field settles to a narrowest gap of %.2f m" % _pk_gap)


func _has_anchor(n: Node) -> bool:
	for c in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).layers == 0:
			return true
		if _has_anchor(c):
			return true
	return false


func _settle(n: int) -> void:
	for i in range(n):
		await process_frame
		await physics_frame


# ── plumbing ──────────────────────────────────────────────────────────────

func _say(line: String) -> void:
	_lines.append("[probe] %s" % line)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
