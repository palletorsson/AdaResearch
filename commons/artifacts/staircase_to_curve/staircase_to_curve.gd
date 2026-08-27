extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name StaircaseToCurve

## @identity
## lineage: the Accumulation hero — the Riemann sum built as a staircase you could
##   climb. Under one continuous brass handrail (the curve), flights of steps march
##   left to right with widths halving flight by flight: four fat steps, then eight,
##   then sixteen — and by the last flight the treads are thin enough that the
##   staircase IS the ramp. The limit, as carpentry.
## essence: accumulation is continuous addition; the rectangles are how addition
##   learns to be continuous. Every flight underestimates the same area a little
##   less, and the handrail never once had to move: the curve was always the limit
##   the steps were saving up for.
## truth: rectangles become the integral the way steps become a slope - by giving up
##   their edges one halving at a time.
##
## The 2026-08-27 category-heroes pass, change. (riemann_pump and integral_area are
## registry-only tokens — promised, never built; the staircase is the rung's first body.)

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 2
@export var run_len: float = 4.4
@export var rail_h: float = 1.7
## Flights of halving widths: 4, 8, 16, 32 steps over four equal quarters of the run.
@export var flights: int = 4

func _curve(u: float) -> float:
	# a rising sweep with a soft crest - positive, monotone-ish, good under a rail
	return rail_h * (0.25 + 0.75 * (u * u * (3.0 - 2.0 * u)))

func _ready() -> void:
	_rng.seed = seed
	_build_steps()
	_build_rail()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "run_len", "rail_h", "flights"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_steps() -> void:
	var tones := [Color(0.78, 0.16, 0.12), Color(0.92, 0.75, 0.14), Color(0.13, 0.30, 0.62), Color(0.20, 0.42, 0.17)]
	for f in range(flights):
		var steps_here := 4 * int(pow(2.0, f))
		var u_from := float(f) / float(flights)
		var u_to := float(f + 1) / float(flights)
		var quarter := (u_to - u_from)
		for i in range(steps_here):
			var u0 := u_from + quarter * float(i) / float(steps_here)
			var u1 := u_from + quarter * float(i + 1) / float(steps_here)
			var um := (u0 + u1) * 0.5
			var h := _curve(um)                    # midpoint rule: the honest height
			var w := (u1 - u0) * run_len
			var step := MeshInstance3D.new()
			var step_mesh := BoxMesh.new()
			step_mesh.size = Vector3(maxf(w - 0.012, 0.008), h, 0.8)
			step.mesh = step_mesh
			step.position = Vector3((u0 + u1) * 0.5 * run_len, h * 0.5, 0.0)
			step.material_override = _matte_mat(tones[f % tones.size()].lerp(Color(0.9, 0.88, 0.85), 0.35), 0.9)
			add_child(step)
		# a small brass counter at each flight's foot: n and its shortfall shrinking
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.2
		tag.position = Vector3((u_from + quarter * 0.5) * run_len, 0.02, 0.62)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text("n = %d" % steps_here, "per quarter - edges halved x%d" % int(pow(2.0, f)))

func _build_rail() -> void:
	# THE CURVE: one continuous brass handrail over everything, segment-built
	var n := 40
	for i in range(n):
		var u0 := float(i) / float(n)
		var u1 := float(i + 1) / float(n)
		var p0 := Vector3(u0 * run_len, _curve(u0) + 0.12, 0.0)
		var p1 := Vector3(u1 * run_len, _curve(u1) + 0.12, 0.0)
		var seg := MeshInstance3D.new()
		var seg_mesh := CylinderMesh.new()
		seg_mesh.top_radius = 0.025
		seg_mesh.bottom_radius = 0.025
		seg_mesh.height = p0.distance_to(p1) * 1.05
		seg.mesh = seg_mesh
		seg.position = (p0 + p1) * 0.5
		seg.rotation.z = atan2(p1.y - p0.y, p1.x - p0.x) + PI * 0.5
		seg.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
		add_child(seg)
	# rail posts every so often, standing ON the steps
	for k in range(5):
		var u := (float(k) + 0.5) / 5.0
		var post := MeshInstance3D.new()
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = 0.016
		post_mesh.bottom_radius = 0.016
		post_mesh.height = 0.14
		post.mesh = post_mesh
		post.position = Vector3(u * run_len, _curve(u) + 0.05, 0.0)
		post.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
		add_child(post)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "StairPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(run_len * 0.35, 0.24, 1.0)
	ts.rotation.y = deg_to_rad(12.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("STAIRCASE TO CURVE - Riemann",
			"Accumulation is continuous addition; rectangles are how addition learns\nto be continuous. Each flight halves its treads and owes the rail a little\nless. The handrail never moved - the curve was always what the steps\nwere saving up for.")
