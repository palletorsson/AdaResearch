extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ParaconsistentRoom

## @identity
## name: Paraconsistent Room — Hold the Contradiction, the World Does Not End
## concept: Florensky & paraconsistency
## tier: large
## lineage: Pavel Florensky, "The Pillar and Ground of the Truth" (1914) — the antinomy
##   held without resolution as a mark of truth; later formalised by da Costa and Priest
##   as paraconsistent logic, where a contradiction does not entail everything (no
##   explosion / ex falso quodlibet).
## essence: a room furnished with held contradictions. Doors stand open-AND-closed, lamps
##   burn on-AND-off, signs read TRUE-AND-FALSE. Classical logic says one contradiction
##   makes everything follow — yet the room sits there, calm and ordinary, persisting.
## truth: a contradiction need not detonate the world. You can hold P and not-P in the
##   same room and keep the floor, the walls, the quiet. Inconsistency is survivable.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent: Color = Color(0.95, 0.55, 0.85)   # the contradiction colour
@export var room_size: float = 7.0
@export var breathe_period: float = 3.4

var _t: float = 0.0
var _doors: Array = []      # each: { "leaf": MeshInstance3D, "hinge": Vector3, "phase": float }
var _lamps: Array = []      # each: StandardMaterial3D (lamp glow flips on/off)
var _signs: Array = []      # each: { "true": Label3D, "false": Label3D }


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("room_size"):
		room_size = float(config["room_size"])
	if config.has("breathe_period"):
		breathe_period = float(config["breathe_period"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_doors = []
	_lamps = []
	_signs = []

	var purple_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.45)
	var white_mat: StandardMaterial3D = _glow_mat(cool_white, 0.4)
	var floor_mat: StandardMaterial3D = _matte_mat(Color(0.08, 0.08, 0.12), 0.9)
	var hs: float = room_size * 0.5

	# --- the room persists: solid floor + chalk border ---
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room_size, 0.06, room_size), floor_mat))
	add_child(_box(Vector3(0.0, 0.01, hs - 0.1), Vector3(room_size - 0.2, 0.01, 0.02), purple_mat))
	add_child(_box(Vector3(0.0, 0.01, -hs + 0.1), Vector3(room_size - 0.2, 0.01, 0.02), purple_mat))
	add_child(_box(Vector3(hs - 0.1, 0.01, 0.0), Vector3(0.02, 0.01, room_size - 0.2), purple_mat))
	add_child(_box(Vector3(-hs + 0.1, 0.01, 0.0), Vector3(0.02, 0.01, room_size - 0.2), purple_mat))

	# --- wireframe wall cage (the room that does NOT collapse) ---
	_build_cage(hs, 2.6)

	# --- doors: open AND closed (two ghost leaves at once) ---
	_build_door(Vector3(-hs + 0.12, 0.0, -1.6), 0.0)
	_build_door(Vector3(hs - 0.12, 0.0, 1.4), PI)
	_build_door(Vector3(0.0, 0.0, -hs + 0.12), -PI * 0.5)

	# --- lamps: on AND off ---
	_build_lamp(Vector3(-1.8, 2.3, -1.8))
	_build_lamp(Vector3(1.8, 2.3, 1.8))
	_build_lamp(Vector3(1.8, 2.3, -1.8))
	_build_lamp(Vector3(-1.8, 2.3, 1.8))

	# --- signs: TRUE AND FALSE ---
	_build_sign(Vector3(0.0, 1.4, hs - 0.2))
	_build_sign(Vector3(-2.2, 1.4, 0.0))
	_build_sign(Vector3(2.2, 1.4, -0.4))

	# a calm central token: the room, unexploded
	add_child(_box(Vector3(0.0, 0.5, 0.0), Vector3(0.5, 0.5, 0.5), _glass_mat(accent, 0.22)))
	add_child(_billboard_label("∧", Vector3(0.0, 0.5, 0.0), 40, accent))

	# --- overhead title ---
	add_child(_billboard_label("HOLD THE CONTRADICTION", Vector3(0.0, 3.6, 0.0), 32, cool_white))
	add_child(_billboard_label("THE WORLD DOES NOT END", Vector3(0.0, 3.3, 0.0), 32, accent))
	add_child(_billboard_label("Florensky — paraconsistency", Vector3(0.0, 3.04, 0.0), 16, wire_purple))


func _build_cage(hs: float, h: float) -> void:
	var edge_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.35)
	var r: float = 0.025
	var corners: Array = [Vector3(-hs, 0.0, -hs), Vector3(hs, 0.0, -hs), Vector3(hs, 0.0, hs), Vector3(-hs, 0.0, hs)]
	for i in range(4):
		var c: Vector3 = corners[i]
		add_child(_cylinder_between(c, c + Vector3(0.0, h, 0.0), r, edge_mat))
	for level in [0.0, h]:
		for i in range(4):
			var a: Vector3 = corners[i] + Vector3(0.0, level, 0.0)
			var b: Vector3 = corners[(i + 1) % 4] + Vector3(0.0, level, 0.0)
			add_child(_cylinder_between(a, b, r, edge_mat))


func _build_door(hinge: Vector3, facing: float) -> void:
	var frame_mat: StandardMaterial3D = _steel_mat(Color(0.32, 0.34, 0.42))
	# frame
	var holder := Node3D.new()
	holder.position = hinge
	holder.rotation.y = facing
	add_child(holder)
	holder.add_child(_box(Vector3(0.0, 1.0, 0.0), Vector3(0.06, 2.0, 0.9), frame_mat))
	# CLOSED leaf (faint, in-plane)
	var leaf_closed: MeshInstance3D = _box(Vector3(0.0, 1.0, 0.42), Vector3(0.05, 1.9, 0.8), _glass_mat(cool_white, 0.28))
	holder.add_child(leaf_closed)
	# OPEN leaf (faint, swung out) — a Node3D pivot so we can swing it
	var pivot := Node3D.new()
	pivot.position = Vector3(0.0, 0.0, 0.0)
	holder.add_child(pivot)
	var leaf_open: MeshInstance3D = _box(Vector3(0.0, 1.0, 0.42), Vector3(0.05, 1.9, 0.8), _glass_mat(accent, 0.28))
	pivot.add_child(leaf_open)
	pivot.rotation.y = -1.2   # swung open
	_doors.append({ "closed": leaf_closed, "open_pivot": pivot, "phase": _rng.randf() * TAU })


func _build_lamp(pos: Vector3) -> void:
	var stem_mat: StandardMaterial3D = _steel_mat(Color(0.3, 0.3, 0.36))
	add_child(_cylinder(pos + Vector3(0.0, 0.18, 0.0), 0.02, 0.36, stem_mat))
	var bulb_mat: StandardMaterial3D = _glow_mat(accent, 1.4)
	add_child(_sphere(pos, 0.1, bulb_mat))
	_lamps.append(bulb_mat)


func _build_sign(pos: Vector3) -> void:
	var board_mat: StandardMaterial3D = _matte_mat(Color(0.12, 0.13, 0.18), 0.85)
	add_child(_box(pos, Vector3(0.7, 0.34, 0.04), board_mat))
	var t_label: Label3D = _billboard_label("TRUE", pos + Vector3(0.0, 0.0, 0.06), 20, cool_white)
	var f_label: Label3D = _billboard_label("FALSE", pos + Vector3(0.0, 0.0, 0.07), 20, accent)
	add_child(t_label)
	add_child(f_label)
	_signs.append({ "t": t_label, "f": f_label })


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var w: float = TAU / breathe_period

	# doors breathe between open and closed — both leaves persist, alpha cross-fades
	for d in _doors:
		var ph: float = d["phase"]
		var s: float = 0.5 + 0.5 * sin(_t * w + ph)
		var closed: MeshInstance3D = d["closed"]
		var pivot: Node3D = d["open_pivot"]
		if is_instance_valid(closed):
			var cm: StandardMaterial3D = closed.material_override as StandardMaterial3D
			if cm != null:
				cm.albedo_color.a = 0.12 + 0.32 * (1.0 - s)
		if is_instance_valid(pivot):
			pivot.rotation.y = -1.2 * s
			var lo: MeshInstance3D = pivot.get_child(0) as MeshInstance3D
			if lo != null:
				var om: StandardMaterial3D = lo.material_override as StandardMaterial3D
				if om != null:
					om.albedo_color.a = 0.12 + 0.32 * s

	# lamps flicker on AND off (never settling) — but never burning the room down
	var k: int = 0
	while k < _lamps.size():
		var lm: StandardMaterial3D = _lamps[k]
		var flick: float = 0.5 + 0.5 * sin(_t * w * 1.3 + float(k) * 1.1)
		lm.emission_energy_multiplier = (1.4 if emissive else 0.5) * (0.15 + flick)
		k += 1

	# signs cross-fade TRUE / FALSE without resolving
	var s_i: int = 0
	while s_i < _signs.size():
		var pair: Dictionary = _signs[s_i]
		var s2: float = 0.5 + 0.5 * sin(_t * w * 0.9 + float(s_i) * 2.0)
		var tl: Label3D = pair["t"]
		var fl: Label3D = pair["f"]
		if is_instance_valid(tl):
			tl.modulate.a = 0.25 + 0.75 * s2
		if is_instance_valid(fl):
			fl.modulate.a = 0.25 + 0.75 * (1.0 - s2)
		s_i += 1
