extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BreathingHallRoom

## @identity
## name: "Breathing & the abject boundary"
## tier: large
## lineage: A hall whose soft walls and columns breathe — bulging inward toward you, then drawing
##   back. The room is not a fixed container; it is a body you stand inside, and it could just as
##   easily close on you as open.
## truth: "IT BREATHES, IT BULGES, IT COULD BURST — THE ROOM IS A BODY AND YOU ARE INSIDE IT"
## applications: lungs from within, pneumatic architecture, the abject body — the boundary that
##   refuses to stay outside you.

@export var room: float = 7.0
@export var col_count: int = 6
@export var breath_rate: float = 0.32
@export var wall_col: Color = Color(0.62, 0.34, 0.42)
@export var column_col: Color = Color(0.78, 0.42, 0.50)
@export var floor_col: Color = Color(0.14, 0.10, 0.12)
@export var label_col: Color = Color(0.96, 0.88, 0.86)

var _t: float = 0.0
var _columns: Array = []   # each: { node:Node3D, phase, base_h }
var _walls: Array = []     # each: { node:Node3D, phase, axis:Vector3 }


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("col_count"):
		col_count = int(clampf(float(config["col_count"]), 4, 10))
	if config.has("breath_rate"):
		breath_rate = clampf(float(config["breath_rate"]), 0.15, 0.6)
	if config.has("wall_col"):
		wall_col = _parse_color(config["wall_col"], wall_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_columns.clear()
	_walls.clear()
	_build()


func _build() -> void:
	var h: float = room * 0.5
	# Floor.
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room, 0.1, room), _matte_mat(floor_col, 0.9)))

	# Four soft walls — bulge toward room centre on their inward axis.
	var wall_specs := [
		{ "pos": Vector3(0, 1.4, -h), "size": Vector3(room, 2.8, 0.3), "axis": Vector3(0, 0, 1) },
		{ "pos": Vector3(0, 1.4, h), "size": Vector3(room, 2.8, 0.3), "axis": Vector3(0, 0, -1) },
		{ "pos": Vector3(-h, 1.4, 0), "size": Vector3(0.3, 2.8, room), "axis": Vector3(1, 0, 0) },
		{ "pos": Vector3(h, 1.4, 0), "size": Vector3(0.3, 2.8, room), "axis": Vector3(-1, 0, 0) },
	]
	var wi: int = 0
	for spec in wall_specs:
		var node := Node3D.new()
		node.position = spec["pos"]
		add_child(node)
		node.add_child(_box(Vector3.ZERO, spec["size"], _glow_mat(wall_col, 0.35)))
		_walls.append({ "node": node, "phase": float(wi) * 0.8, "axis": spec["axis"] })
		wi += 1

	# A ring of breathing columns — soft pillars that swell radially.
	for p in range(col_count):
		var ang: float = TAU * float(p) / float(col_count)
		var rad: float = room * 0.30
		var base := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		var node2 := Node3D.new()
		node2.position = base
		add_child(node2)
		# A column built of stacked soft spheres so it can bulge in the middle.
		var seg: int = 5
		for s in range(seg):
			var sy: float = 0.4 + float(s) * 0.5
			node2.add_child(_sphere(Vector3(0.0, sy, 0.0), 0.28, _glow_mat(column_col, 0.45)))
		_columns.append({ "node": node2, "phase": float(p) * 0.9, "base_h": float(seg) })

	add_child(_billboard_label("IT BREATHES, IT BULGES, IT COULD BURST", Vector3(0.0, 3.6, 0.0), 26, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var breath: float = sin(_t * TAU * breath_rate)
	# Columns swell horizontally and pulse vertically.
	for idx in range(_columns.size()):
		var col: Dictionary = _columns[idx]
		var node: Node3D = col["node"]
		var ph: float = col["phase"]
		var b: float = sin(_t * TAU * breath_rate + ph)
		var sx: float = 1.0 + b * 0.22
		node.scale = Vector3(sx, 1.0 + b * 0.08, sx)
	# Walls bulge inward toward the room centre, then retreat.
	for widx in range(_walls.size()):
		var w: Dictionary = _walls[widx]
		var wnode: Node3D = w["node"]
		var axis: Vector3 = w["axis"]
		var wph: float = w["phase"]
		var push: float = (sin(_t * TAU * breath_rate + wph) * 0.5 + 0.5) * 0.7
		# Move the wall inward along its axis as it "inhales".
		var base_pos: Vector3 = axis * (-room * 0.5)   # rough outer position
		# Reconstruct a stable base from current direction (axis points inward).
		wnode.position = wnode.position.lerp(_wall_base(axis) + axis * push, 0.1)


func _wall_base(axis: Vector3) -> Vector3:
	var h: float = room * 0.5
	# Outer wall position is opposite the inward axis.
	return Vector3(-axis.x * h, 1.4, -axis.z * h)
