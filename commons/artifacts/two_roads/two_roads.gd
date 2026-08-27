extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TwoRoads

## @identity
## lineage: the color taxonomy's rung 8 — two walkable roads between the same two
##   colours, teal to orange. The left road interpolates in RGB and greys out in the
##   middle, the way Color.lerp does; the right road walks the HSV wheel and stays
##   saturated the whole way, passing through green and gold to arrive.
## essence: between two colours there are many roads. The engine's lerp is a straight
##   line through the RGB cube — and the cube's centre is mud. from_hsv walks around
##   the wheel instead. Same departure, same arrival, different countries crossed.
## truth: a gradient is a CHOICE of path, not a fact about its endpoints.
##
## The 2026-08-27 color taxonomy (doc/COLOR_TAXONOMY.md), rung 8 of 12.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const A := Color(0.0, 0.6, 0.8)         # teal — hue ~0.53
const B := Color(0.95, 0.55, 0.1)       # orange — hue ~0.09

@export var seed: int = 28
@export var length: float = 6.0
@export_range(12, 40) var steps: int = 24
@export var road_w: float = 0.9

func _ready() -> void:
	_rng.seed = seed
	_build_road(-road_w * 0.65 - 0.35, true)    # RGB, the mud road
	_build_road(road_w * 0.65 + 0.35, false)    # HSV, the wheel road
	_build_gates()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "length", "steps"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- the roads ----------------------------------------------------------------------

func _rgb_at(t: float) -> Color:
	return A.lerp(B, t)

func _hsv_at(t: float) -> Color:
	# teal 0.53 down through green and gold to orange 0.09 — the saturated way round
	var ha := 0.53
	var hb := 0.09
	return Color.from_hsv(lerpf(ha, hb, t), lerpf(0.95, 0.9, t), lerpf(0.85, 0.95, t))

func _build_road(x: float, rgb: bool) -> void:
	var tile_l := length / float(steps)
	for k in range(steps):
		var t := (float(k) + 0.5) / float(steps)
		var c := _rgb_at(t) if rgb else _hsv_at(t)
		var tile := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(road_w, 0.06, tile_l * 0.94)
		tile.mesh = tm
		tile.position = Vector3(x, 0.03, -length * 0.5 + tile_l * (float(k) + 0.5))
		var mat := _matte_mat(c, 0.55)
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = 0.35 if emissive else 0.12
		tile.material_override = mat
		add_child(tile)
	# a kerb naming the road, halfway along
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.24
	tag.position = Vector3(x + (road_w * 0.5 + 0.16) * (1.0 if rgb else -1.0) * -1.0, 0.2, 0.0)
	tag.rotation.y = deg_to_rad(90.0 if rgb else -90.0)
	add_child(tag)
	if tag.has_method("set_text"):
		if rgb:
			tag.set_text("RGB ROAD", "Color.lerp - straight through the cube, and the middle is mud")
		else:
			tag.set_text("HSV ROAD", "from_hsv - round the wheel, saturated the whole way")

func _build_gates() -> void:
	# departure and arrival: two arches painted the endpoint colours, shared by both roads
	for spec in [[-length * 0.5 - 0.15, A], [length * 0.5 + 0.15, B]]:
		var z: float = spec[0]
		var c: Color = spec[1]
		var mat := _glow_mat(c, 1.1)
		for sx in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.12, 2.0, 0.12)
			post.mesh = pm
			post.position = Vector3(sx * (road_w * 1.3 + 0.45), 1.0, z)
			post.material_override = mat
			add_child(post)
		var lintel := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(road_w * 2.6 + 1.05, 0.14, 0.14)
		lintel.mesh = lm
		lintel.position = Vector3(0.0, 2.05, z)
		lintel.material_override = mat
		add_child(lintel)
	# the mud exhibit: the RGB road's exact midpoint colour, held up on a small plinth
	# between the roads like evidence
	var mid := _rgb_at(0.5)
	var plinth := MeshInstance3D.new()
	var plm := CylinderMesh.new()
	plm.top_radius = 0.09
	plm.bottom_radius = 0.11
	plm.height = 0.85
	plinth.mesh = plm
	plinth.position = Vector3(0.0, 0.425, 0.0)
	plinth.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
	add_child(plinth)
	var mud := MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 0.11
	mm.height = 0.22
	mud.mesh = mm
	mud.position = Vector3(0.0, 0.95, 0.0)
	mud.material_override = _matte_mat(mid, 0.6)
	add_child(mud)

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "RoadsPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-road_w * 1.3 - 0.7, 0.24, -length * 0.5 + 0.4)
	ts.rotation.y = deg_to_rad(40.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("TWO ROADS",
			"Same two colours, two roads. RGB cuts straight through the cube and greys\nout in the middle - the sphere on the plinth is that exact mud. HSV walks\nthe wheel through green and gold, saturated all the way. A gradient is a choice.")
