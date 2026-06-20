extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TurtlePlotter

## @identity
## lineage: Turtle interpretation, applied — a pen-plotter whose arm IS the turtle, the
##   curve already drawn on the plate beneath it.
## essence: the abstraction made into a machine. A real pen, a real arm, a real plate;
##   the L-system string is the G-code.
## truth: a plotter is the turtle in hardware. Forward feeds the pen, turn swings the
##   arm; the grammar becomes motion and the motion becomes a line.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var iterations: int = 2
@export var angle_deg: float = 25.0
@export var ink_color: Color = Color(0.20, 0.90, 0.75)
@export var ink_tip_color: Color = Color(0.55, 1.0, 0.90)
@export var trace_speed: float = 0.35


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
	# --- plotter body: a flat ~1m device ---
	var body_mat := _matte_mat(Color(0.17, 0.18, 0.21), 0.8)
	add_child(_box(Vector3(0, 0.06, 0), Vector3(1.0, 0.12, 0.8), body_mat))
	# the drawing plate (paper) sunk into the top
	var plate_mat := _matte_mat(Color(0.92, 0.93, 0.95), 0.5)
	add_child(_box(Vector3(0, 0.125, 0), Vector3(0.78, 0.02, 0.6), plate_mat))
	# rails along the long axis
	var rail_mat := _steel_mat(Color(0.55, 0.57, 0.60))
	add_child(_cylinder_between(Vector3(-0.45, 0.20, -0.34), Vector3(0.45, 0.20, -0.34), 0.012, rail_mat))
	add_child(_cylinder_between(Vector3(-0.45, 0.20, 0.34), Vector3(0.45, 0.20, 0.34), 0.012, rail_mat))

	# --- the curve already drawn onto the plate, lying flat ---
	var axiom := "F+F-[F]-F+F"
	var rules := {"F": "F+F-F"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iterations), {
		"angle_deg": angle_deg, "step_len": 0.06, "step_shrink": 1.0,
		"base_width": 0.012, "width_shrink": 1.0, "seed": 1,
	})
	var curve: MeshInstance3D = LST.to_lines(walk, ink_color, ink_tip_color)
	curve.rotation_degrees = Vector3(-90.0, 0.0, 0.0)  # draw plane -> plate top
	curve.name = "Ink"
	add_child(curve)
	var pen_world := _fit_plate_curve(curve, walk, 0.6, 0.138)

	# --- gantry bridge that carries the pen carriage ---
	add_child(_box(Vector3(pen_world.x, 0.30, 0.0), Vector3(0.06, 0.20, 0.74), rail_mat))
	# pen carriage + the pen itself, parked at the curve's last point
	var carriage_mat := _matte_mat(Color(0.22, 0.24, 0.28), 0.6)
	add_child(_box(Vector3(pen_world.x, 0.30, pen_world.z), Vector3(0.10, 0.10, 0.10), carriage_mat))
	var pen_mat := _glow_mat(ink_color, 0.8)
	# pen body tapering down to the plate
	add_child(_cylinder(Vector3(pen_world.x, 0.255, pen_world.z), 0.018, 0.13, _steel_mat(Color(0.6, 0.62, 0.65))))
	var nib := MeshInstance3D.new()
	var nm := CylinderMesh.new()
	nm.top_radius = 0.012
	nm.bottom_radius = 0.0
	nm.height = 0.05
	nib.mesh = nm
	nib.material_override = pen_mat
	nib.position = Vector3(pen_world.x, 0.165, pen_world.z)
	nib.name = "PenNib"
	add_child(nib)

	# --- readout label ---
	add_child(_box(Vector3(0.0, 0.34, -0.42), Vector3(0.5, 0.16, 0.02), _glow_mat(Color(0.08, 0.10, 0.14), 0.6)))
	add_child(_billboard_label("F+F-[F]-F+F", Vector3(0.0, 0.34, -0.40), 16, Color(0.55, 1.0, 0.90)))
	add_child(_billboard_label("TURTLE PLOTTER", Vector3(0, 0.62, 0), 26, Color(0.85, 0.95, 1.0)))


func _fit_plate_curve(curve: MeshInstance3D, walk: Dictionary, target_span: float, lift: float) -> Vector3:
	var segments: Array = walk["segments"]
	if segments.is_empty():
		return Vector3(0, lift, 0)
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for seg: Array in segments:
		for k: int in [0, 1]:
			var p: Vector3 = seg[k]
			mn = Vector3(minf(mn.x, p.x), minf(mn.y, p.y), minf(mn.z, p.z))
			mx = Vector3(maxf(mx.x, p.x), maxf(mx.y, p.y), maxf(mx.z, p.z))
	var span := maxf(mx.x - mn.x, mx.y - mn.y)
	var s := target_span / maxf(span, 0.001)
	curve.scale = Vector3.ONE * s
	var cx := (mn.x + mx.x) * 0.5 * s
	var cy := (mn.y + mx.y) * 0.5 * s
	curve.position = Vector3(-cx, lift, cy)
	# world position of the pen (last drawn point) after the -90° X rotation:
	# local (x, y) -> world (x, -, -y), then translated by curve.position.
	var last: Array = segments[segments.size() - 1]
	var lp: Vector3 = last[1]
	return Vector3(curve.position.x + lp.x * s, lift, curve.position.z - lp.y * s)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# gentle pen bob to suggest it is "drawing"
	var nib := get_node_or_null("PenNib")
	if nib:
		nib.position.y = 0.165 + absf(sin(Time.get_ticks_msec() * 0.004)) * 0.01
