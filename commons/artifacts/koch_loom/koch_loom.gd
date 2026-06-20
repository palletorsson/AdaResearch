extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name KochLoom

## @identity
## lineage: Koch & fractal curves, applied — the Koch curve as the edge of woven cloth,
##   a loom paying out a bolt whose selvage is fractal.
## essence: the famous infinite-perimeter edge made into textile. Each pick of the shuttle
##   lays another Koch row; the bolt scrolls off the frame.
## truth: a finite area bordered by an endless edge. F -> F+F-F-F+F at every scale, the
##   coastline paradox you can roll up and carry.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var iterations: int = 4
@export var rows: int = 7
@export var cloth_color: Color = Color(0.85, 0.45, 0.65)
@export var cloth_tip_color: Color = Color(1.0, 0.75, 0.40)
@export var scroll_speed: float = 0.18


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


func _expand(axiom: String, rules: Dictionary, iters: int) -> String:
	var s := axiom
	for _i in range(iters):
		var out := ""
		for ch: String in s:
			out += String(rules.get(ch, ch))
		s = out
	return s


func _build() -> void:
	# --- loom frame: two uprights + a top beam ---
	var frame_mat := _matte_mat(Color(0.32, 0.22, 0.14), 0.7)
	add_child(_box(Vector3(-0.65, 0.55, 0.0), Vector3(0.08, 1.1, 0.12), frame_mat))
	add_child(_box(Vector3(0.65, 0.55, 0.0), Vector3(0.08, 1.1, 0.12), frame_mat))
	add_child(_box(Vector3(0.0, 1.06, 0.0), Vector3(1.38, 0.08, 0.12), frame_mat))
	# warp beam (a roller) at the bottom where the bolt rolls off
	var roller_mat := _steel_mat(Color(0.55, 0.50, 0.45))
	add_child(_cylinder_between(Vector3(-0.62, 0.14, 0.0), Vector3(0.62, 0.14, 0.0), 0.06, roller_mat))

	# --- the bolt of cloth: Koch curves stacked as woven rows ---
	# one Koch row, then duplicated downward in a scrolling holder.
	var axiom := "F"
	var rules := {"F": "F+F-F-F+F"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iterations), {
		"angle_deg": 90.0, "step_len": 0.05, "step_shrink": 1.0,
		"base_width": 0.010, "width_shrink": 1.0, "seed": 1,
	})
	# measure the row so we can fit it across the frame width.
	var bounds := _row_bounds(walk)
	var row_w: float = maxf(bounds.size.x, 0.001)
	var fit: float = 1.18 / row_w  # span the inner frame width (~1.18m)
	var bolt := Node3D.new()
	bolt.name = "Bolt"
	add_child(bolt)
	var row_gap := 0.115
	for ri: int in range(rows):
		var row: MeshInstance3D = LST.to_lines(walk, cloth_color, cloth_tip_color)
		row.scale = Vector3.ONE * fit
		# centre horizontally; stack vertically inside the frame, top row near the beam.
		row.position = Vector3(-bounds.position.x * fit - (row_w * fit) * 0.5, 0.95 - float(ri) * row_gap, 0.0)
		row.name = "Row_%d" % ri
		bolt.add_child(row)

	# --- shuttle that "weaves" the topmost pick ---
	var shuttle_mat := _glow_mat(Color(1.0, 0.85, 0.40), 0.8)
	var shuttle := _box(Vector3(-0.4, 0.97, 0.02), Vector3(0.10, 0.04, 0.05), shuttle_mat)
	shuttle.name = "Shuttle"
	add_child(shuttle)

	# --- readout label ---
	add_child(_box(Vector3(0.0, 0.34, -0.08), Vector3(0.6, 0.0, 0.0), frame_mat))  # spacer (no-op visual anchor)
	add_child(_billboard_label("F -> F+F-F-F+F", Vector3(0.0, 0.30, 0.10), 16, Color(1.0, 0.80, 0.55)))
	add_child(_billboard_label("KOCH LOOM", Vector3(0, 1.34, 0), 28, Color(0.95, 0.85, 0.95)))


func _row_bounds(walk: Dictionary) -> AABB:
	var segments: Array = walk["segments"]
	if segments.is_empty():
		return AABB(Vector3.ZERO, Vector3.ONE)
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for seg: Array in segments:
		for k: int in [0, 1]:
			var p: Vector3 = seg[k]
			mn = Vector3(minf(mn.x, p.x), minf(mn.y, p.y), minf(mn.z, p.z))
			mx = Vector3(maxf(mx.x, p.x), maxf(mx.y, p.y), maxf(mx.z, p.z))
	return AABB(mn, mx - mn)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# scroll the bolt downward and wrap, so it reads as cloth paying off the roller.
	var bolt := get_node_or_null("Bolt")
	if bolt:
		bolt.position.y -= scroll_speed * delta
		if bolt.position.y <= -0.115:
			bolt.position.y += 0.115
	# shuttle tracks across the top pick
	var shuttle := get_node_or_null("Shuttle")
	if shuttle:
		shuttle.position.x = sin(Time.get_ticks_msec() * 0.0016) * 0.5
