extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TurtleBench

## @identity
## lineage: Turtle interpretation bench — F/+/- commands read left to right become a path
## essence: a workbench where the command string sits beside the line it draws, a turtle
##   cursor parked at the pen's last position.
## truth: the string is not the picture; the turtle IS the interpreter. FORWARD draws,
##   TURN rotates, BRANCH remembers a place to return to. Geometry is a reading of symbols.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var iterations: int = 2
@export var angle_deg: float = 25.0
@export var trunk_color: Color = Color(0.55, 0.80, 1.0)
@export var tip_color: Color = Color(0.45, 0.95, 0.55)
@export var panel_color: Color = Color(0.10, 0.12, 0.16)


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
	# --- bench base ---
	var base_mat := _matte_mat(Color(0.16, 0.17, 0.20), 0.85)
	add_child(_box(Vector3(0, 0.42, 0), Vector3(1.1, 0.2, 0.7), base_mat))
	# four short legs
	var leg_mat := _steel_mat(Color(0.30, 0.31, 0.34))
	for sx: float in [-0.45, 0.45]:
		for sz: float in [-0.27, 0.27]:
			add_child(_cylinder(Vector3(sx, 0.21, sz), 0.03, 0.42, leg_mat))
	# pillar holding the drawing up to ~0.85 top
	var pillar_mat := _steel_mat(Color(0.34, 0.35, 0.38))
	add_child(_cylinder(Vector3(0, 0.66, 0.1), 0.05, 0.32, pillar_mat))
	add_child(_cylinder(Vector3(0, 0.84, 0.1), 0.10, 0.03, pillar_mat))

	# --- command-string panel ---
	var panel_mat := _glow_mat(panel_color, 0.6)
	add_child(_box(Vector3(0, 1.05, -0.20), Vector3(0.95, 0.26, 0.02), panel_mat))
	add_child(_billboard_label("COMMANDS", Vector3(0, 1.15, -0.18), 22, Color(0.55, 0.80, 1.0)))
	add_child(_billboard_label("F + F - [ F ] - F + F", Vector3(0, 1.02, -0.18), 22, Color(0.90, 0.95, 1.0)))

	# --- the path the turtle draws, on top, facing +Z ---
	var axiom := "F+F-[F]-F+F"
	var rules := {"F": "F+F-F"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iterations), {
		"angle_deg": angle_deg, "step_len": 0.07, "step_shrink": 1.0,
		"base_width": 0.014, "width_shrink": 1.0, "seed": 1,
	})
	var curve: MeshInstance3D = LST.to_lines(walk, trunk_color, tip_color)
	# lift onto the pillar top, face the player (+Z); the turtle walks in the X/Y plane
	curve.position = Vector3(-0.35, 0.90, 0.10)
	curve.scale = Vector3.ONE * 0.7
	curve.name = "Path"
	add_child(curve)

	# --- turtle cursor: a small cone parked at the path's last point ---
	var segments: Array = walk["segments"]
	var pen_local := Vector3.ZERO
	var heading := Vector3.UP
	if not segments.is_empty():
		var last: Array = segments[segments.size() - 1]
		pen_local = last[1]
		var pen_a: Vector3 = last[0]
		if pen_local.distance_to(pen_a) > 1e-5:
			heading = (pen_local - pen_a).normalized()
	var pen_world := curve.position + (pen_local * curve.scale.x)
	var turtle_mat := _glow_mat(Color(1.0, 0.78, 0.30), 0.9)
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.035
	cm.height = 0.09
	cone.mesh = cm
	cone.material_override = turtle_mat
	cone.transform = Transform3D(_basis_y_to(heading), pen_world)
	cone.name = "Turtle"
	add_child(cone)

	# --- title label ---
	add_child(_billboard_label("FORWARD, TURN, BRANCH", Vector3(0, 1.6, 0.1), 28, Color(0.85, 0.92, 1.0)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var path := get_node_or_null("Path")
	if path:
		path.rotation.y += delta * 0.2
	var turtle := get_node_or_null("Turtle")
	if turtle:
		turtle.position.y += sin(Time.get_ticks_msec() * 0.003) * delta * 0.05
