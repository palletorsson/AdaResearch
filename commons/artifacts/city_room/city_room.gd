extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CityRoom

## CityRoom — Grammar architecture (cities/dungeons), LARGE tier.
##
## A room-scale L-system city/dungeon: orthogonal walls and streets you
## could walk, low glowing walls laid on the floor. The same engine that
## grows a tree, pointed at right angles, grows a dungeon.
##
## @identity
##   truth: "point the rules at right angles and the same engine grows a city"
##   truth: "streets, dungeons, pipe networks — one grammar, many readings"

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var axiom: String = "F"
@export var rules: Dictionary = {"F": "FF+[+F-F-F]-[-F+F+F]"}
@export var iters: int = 3
@export var angle: float = 90.0
@export var c1: Color = Color(0.35, 0.4, 0.5)
@export var c2: Color = Color(0.5, 0.9, 1.0)
@export var wall_height: float = 0.6
@export var plan_scale: float = 5.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("axiom"):
		axiom = String(config["axiom"])
	if config.has("iters"):
		iters = int(config["iters"])
	if config.has("angle"):
		angle = float(config["angle"])
	if config.has("c1"):
		c1 = _parse_color(config["c1"], c1)
	if config.has("c2"):
		c2 = _parse_color(config["c2"], c2)
	for child in get_children():
		child.queue_free()
	_build()


func _expand(p_axiom: String, p_rules: Dictionary, p_iters: int) -> String:
	var s := p_axiom
	for _i in range(p_iters):
		var out := ""
		for ch: String in s:
			out += String(p_rules.get(ch, ch))
		s = out
	return s


func _build() -> void:
	# --- room floor -----------------------------------------------------------
	var floor_mat := _matte_mat(Color(0.09, 0.1, 0.12), 0.9)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), floor_mat))

	# --- city/dungeon plan grown across the floor -----------------------------
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
		"angle_deg": angle, "step_len": 0.08, "step_shrink": 0.85,
		"base_width": 0.02, "width_shrink": 0.8, "seed": 1,
	})

	# Build low glowing walls per segment, projected flat onto the floor.
	# Turtle plane is X (left/right) by Y (forward heading) → map Y → Z floor.
	var segments: Array = walk["segments"]
	var wall_mat := _glow_mat(c2, 1.2)
	var floor_y: float = 0.0
	for seg: Array in segments:
		var a3: Vector3 = seg[0]
		var b3: Vector3 = seg[1]
		# project turtle (x, y) onto floor (x, z), scale to room
		var a := Vector3(a3.x * plan_scale, floor_y + wall_height * 0.5, a3.y * plan_scale)
		var b := Vector3(b3.x * plan_scale, floor_y + wall_height * 0.5, b3.y * plan_scale)
		if a.distance_to(b) < 0.001:
			continue
		# wall as a box along the segment
		var mid: Vector3 = (a + b) * 0.5
		var seg_len: float = a.distance_to(b)
		var dir: Vector3 = (b - a).normalized()
		var box := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.12, wall_height, seg_len)
		box.mesh = mesh
		box.material_override = wall_mat
		var yaw: float = atan2(dir.x, dir.z)
		box.transform = Transform3D(Basis(Vector3.UP, yaw), mid)
		add_child(box)

	# --- node markers at intersections ---------------------------------------
	var g: Dictionary = LST.to_graph(walk)
	var node_mat := _glow_mat(c2, 1.8)
	for p: Vector3 in g["positions"]:
		var fp := Vector3(p.x * plan_scale, floor_y + 0.05, p.y * plan_scale)
		add_child(_sphere(fp, 0.06, node_mat))

	# --- overhead headline ----------------------------------------------------
	add_child(_billboard_label("STREETS, DUNGEONS, PIPE NETWORKS", Vector3(0.0, 3.6, 0.0), 40, c2))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# static plan — gentle emissive pulse via no transform; idle only
	pass
