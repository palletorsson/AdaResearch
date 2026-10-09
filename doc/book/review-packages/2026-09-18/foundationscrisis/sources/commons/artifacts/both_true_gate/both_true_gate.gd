extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BothTrueGate

## @identity
## name: Both-True Gate
## lineage: Florensky's paraconsistency — a contradiction the system SURVIVES.
##   Classical logic explodes on contradiction (ex falso quodlibet: from P and
##   not-P, everything follows). A paraconsistent system holds the contradiction
##   locally without trivialising the whole world.
## essence: one door-frame holding TWO superposed leaves at once — one swung OPEN,
##   one shut FLUSH — ghosted together in the same opening, neither winning. A
##   steady "BOTH TRUE" plate sits on the lintel. Behind the gate a small calm
##   world (floor, horizon, three quiet markers) keeps standing: nothing follows,
##   the explosion never comes.
## truth: P and not-P, and the world does not end — the contradiction is contained,
##   not detonated.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.92, 0.94, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent_violet: Color = Color(0.78, 0.36, 0.92)
@export var calm_blue: Color = Color(0.42, 0.60, 0.92)
@export var breathe_period: float = 4.0

var _leaf_open: Node3D
var _leaf_shut: Node3D
var _both_plate: Label3D
var _world_root: Node3D
var _t: float = 0.0

const FRAME_W: float = 0.66          # inner opening width (x)
const FRAME_H: float = 0.92          # inner opening height (y), top ~1.0m + frame
const JAMB: float = 0.05             # frame thickness
const Y_BASE: float = 0.0            # frame sill on the floor


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# --- chalk ring on the floor (no bench) ---
	var ring_mat := _glow_mat(wire_purple, 0.5)
	add_child(_torus(Vector3(0.0, 0.02, 0.0), 0.58, 0.012, ring_mat))

	var white := _matte_mat(cool_white, 0.5)
	var wire := _glow_mat(wire_purple, 0.85)

	# === THE DOOR FRAME (one frame, holds both leaves) ===
	var hw: float = FRAME_W * 0.5 + JAMB * 0.5
	# left & right jambs
	add_child(_box(Vector3(-hw, Y_BASE + FRAME_H * 0.5, 0.0), Vector3(JAMB, FRAME_H + JAMB, JAMB), white))
	add_child(_box(Vector3(hw, Y_BASE + FRAME_H * 0.5, 0.0), Vector3(JAMB, FRAME_H + JAMB, JAMB), white))
	# lintel
	add_child(_box(Vector3(0.0, Y_BASE + FRAME_H + JAMB * 0.5, 0.0), Vector3(FRAME_W + JAMB * 2.0, JAMB, JAMB), white))
	# sill on the floor
	add_child(_box(Vector3(0.0, Y_BASE + 0.01, 0.0), Vector3(FRAME_W + JAMB * 2.0, 0.02, JAMB), wire))
	# wire outline of the opening so the threshold reads as a drawn rectangle
	add_child(_box(Vector3(-FRAME_W * 0.5, Y_BASE + FRAME_H * 0.5, 0.0), Vector3(0.008, FRAME_H, 0.01), wire))
	add_child(_box(Vector3(FRAME_W * 0.5, Y_BASE + FRAME_H * 0.5, 0.0), Vector3(0.008, FRAME_H, 0.01), wire))

	# === LEAF A — SHUT (flush in the opening) ===
	# hinged on the left jamb, closed across the frame.
	_leaf_shut = Node3D.new()
	_leaf_shut.position = Vector3(-FRAME_W * 0.5, Y_BASE + FRAME_H * 0.5, 0.0)  # hinge at left edge
	add_child(_leaf_shut)
	_build_leaf(_leaf_shut, accent_violet, 0.20)   # ghosted, "closed" tint

	# === LEAF B — OPEN (swung ~80 deg toward the viewer) ===
	# the SAME door, also hinged on the left jamb, but standing open. Both occupy
	# the frame at once; neither is the real one.
	_leaf_open = Node3D.new()
	_leaf_open.position = Vector3(-FRAME_W * 0.5, Y_BASE + FRAME_H * 0.5, 0.0)   # same hinge
	add_child(_leaf_open)
	_build_leaf(_leaf_open, calm_blue, 0.20)        # ghosted, "open" tint
	_leaf_open.rotation.y = deg_to_rad(80.0)

	# === THE STEADY WORLD BEHIND THE GATE ===
	# Small, calm, and persistent — the proof that nothing follows. A floor slab,
	# a horizon line, and three quiet upright markers that simply keep standing.
	_world_root = Node3D.new()
	_world_root.position = Vector3(0.0, 0.0, -0.34)   # set back, behind the frame
	add_child(_world_root)
	var world_floor := _matte_mat(Color(0.16, 0.18, 0.26), 0.9)
	_world_root.add_child(_box(Vector3(0.0, Y_BASE + 0.005, -0.18), Vector3(FRAME_W * 1.4, 0.01, 0.5), world_floor))
	# a calm horizon bar
	var horizon := _glow_mat(calm_blue, 0.6)
	_world_root.add_child(_box(Vector3(0.0, Y_BASE + 0.40, -0.42), Vector3(FRAME_W * 1.3, 0.012, 0.012), horizon))
	# three quiet markers (the world's furniture — unbothered by the contradiction)
	var marker := _matte_mat(cool_white, 0.6)
	var mxs: Array[float] = [-0.20, 0.02, 0.22]
	for i in range(3):
		var mx: float = mxs[i]
		_world_root.add_child(_cylinder(Vector3(mx, Y_BASE + 0.10, -0.20 - 0.04 * float(i)), 0.018, 0.20, marker))
		_world_root.add_child(_sphere(Vector3(mx, Y_BASE + 0.21, -0.20 - 0.04 * float(i)), 0.026, horizon))

	# --- the steady "BOTH TRUE" plate on the lintel ---
	_both_plate = _billboard_label("BOTH TRUE", Vector3(0.0, Y_BASE + FRAME_H + 0.16, 0.0), 24, accent_violet)
	add_child(_both_plate)
	# the two contradicting verdicts, side by side, both lit
	add_child(_billboard_label("OPEN", Vector3(-0.34, Y_BASE + FRAME_H * 0.5, 0.30), 16, calm_blue))
	add_child(_billboard_label("CLOSED", Vector3(0.30, Y_BASE + FRAME_H * 0.5, 0.06), 16, accent_violet))

	# --- titles ---
	add_child(_billboard_label("BOTH-TRUE GATE", Vector3(0.0, 1.5, 0.0), 30, cool_white))
	add_child(_billboard_label("P and not-P — and the world does not end", Vector3(0.0, 1.36, 0.0), 16, accent_violet))


# Build a single ghosted door leaf hinged at local origin (left edge), extending
# +x across the opening. Drawn as a translucent panel with wire stiles/rails.
func _build_leaf(root: Node3D, tint: Color, alpha: float) -> void:
	var panel := _glass_mat(tint, alpha)
	var edge := _glow_mat(tint, 1.0)
	var w: float = FRAME_W
	var h: float = FRAME_H - 0.02
	# panel centred half a width along +x from the hinge
	root.add_child(_box(Vector3(w * 0.5, 0.0, 0.0), Vector3(w, h, 0.012), panel))
	# stiles (vertical edges)
	root.add_child(_box(Vector3(0.012, 0.0, 0.0), Vector3(0.012, h, 0.02), edge))
	root.add_child(_box(Vector3(w - 0.012, 0.0, 0.0), Vector3(0.012, h, 0.02), edge))
	# rails (top & bottom)
	root.add_child(_box(Vector3(w * 0.5, h * 0.5 - 0.006, 0.0), Vector3(w, 0.012, 0.02), edge))
	root.add_child(_box(Vector3(w * 0.5, -h * 0.5 + 0.006, 0.0), Vector3(w, 0.012, 0.02), edge))
	# a small handle on the latch edge
	root.add_child(_sphere(Vector3(w - 0.05, 0.0, 0.03), 0.022, edge))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# Neither leaf wins. They breathe in opposite phase — as the open leaf brightens,
	# the shut leaf dims, then they swap — but BOTH always remain present (alpha
	# never reaches 0). The contradiction is held, not resolved.
	var phase: float = fmod(_t, breathe_period) / breathe_period
	var sway: float = sin(phase * TAU)            # -1..1
	var bal: float = 0.5 + 0.5 * sway              # 0..1 weight toward "open"

	if is_instance_valid(_leaf_open):
		# open leaf eases between ~70 and ~88 degrees, never fully shut
		_leaf_open.rotation.y = deg_to_rad(lerp(70.0, 88.0, bal))
		_set_leaf_alpha(_leaf_open, lerp(0.14, 0.34, bal))
	if is_instance_valid(_leaf_shut):
		# shut leaf stays flush (≈0 deg) but its presence waxes as the other wanes
		_leaf_shut.rotation.y = deg_to_rad(lerp(0.0, 6.0, 1.0 - bal))
		_set_leaf_alpha(_leaf_shut, lerp(0.14, 0.34, 1.0 - bal))

	# the BOTH TRUE plate holds steady — a calm, constant pulse, not a flicker
	if is_instance_valid(_both_plate):
		var glow: float = 0.5 + 0.5 * sin(_t * 1.5)
		_both_plate.modulate = accent_violet.lerp(cool_white, glow * 0.3)

	# the world behind keeps its quiet life: markers bob a hair, nothing explodes
	if is_instance_valid(_world_root):
		var n: int = _world_root.get_child_count()
		for i in range(n):
			var ch: Node = _world_root.get_child(i)
			if ch is MeshInstance3D and (ch as MeshInstance3D).mesh is SphereMesh:
				var mi := ch as MeshInstance3D
				mi.position.y += sin(_t * 1.2 + float(i)) * 0.0006


# Walk a leaf's children and nudge the translucent panel + edge alphas.
func _set_leaf_alpha(root: Node3D, a: float) -> void:
	for ch in root.get_children():
		if ch is MeshInstance3D:
			var mi := ch as MeshInstance3D
			var mat := mi.material_override
			if mat is StandardMaterial3D:
				var sm := mat as StandardMaterial3D
				if sm.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
					sm.albedo_color.a = a
