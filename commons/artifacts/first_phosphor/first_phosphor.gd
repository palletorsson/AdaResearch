extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FirstPhosphor

## @identity
## lineage: the medium's nativity, built as an altar piece — one oscilloscope on a lab
##   cart, black velvet shroud behind it, and on the scope's dark glass ONE green
##   phosphor dot. In a cathode-ray tube, "let there be light" and "first there was a
##   point" are the same event: an electron beam making one dot glow. Tennis for Two
##   ran on a scope like this in 1958; Spacewar's ships were points on one in 1962.
## essence: the dot breathes with phosphor persistence and BLINKS at the terminal's
##   cadence — 530 ms, the cursor's heartbeat — because the blinking cursor is this
##   dot's living descendant: a point, pulsing, that contains every possible world and
##   waits for the word.
## truth: this medium's Genesis needed no separation of light from dark. It was given
##   both at once, in one point, on glass.
##
## 2026-08-27, from the conversation on beginnings: "how do we pay tribute to the
## beginning?" Like this.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const PHOSPHOR := Color(0.35, 1.0, 0.45)

@export var seed: int = 1958
## The cursor cadence, seconds on / seconds off. 0.53 is the terminal's heartbeat.
@export var blink_s: float = 0.53
## Where the dot sits on the glass, scope-local. Slightly off-centre, like a serve
## about to happen.
@export var dot_pos: Vector2 = Vector2(0.06, 0.03)

var _dot: MeshInstance3D
var _halo: MeshInstance3D
var _t := 0.0

func _ready() -> void:
	_rng.seed = seed
	_build_cart()
	_build_scope()
	_build_shroud()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "blink_s"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	if _dot == null:
		return
	_t += delta
	# the blink is square (a cursor), the decay inside each ON phase is phosphor:
	# bright at strike, easing as the persistence spends itself
	var phase := fmod(_t, blink_s * 2.0)
	var on := phase < blink_s
	var persistence := 1.0 - (phase / blink_s) * 0.35 if on else 0.0
	var mat := _dot.material_override as StandardMaterial3D
	mat.emission_energy_multiplier = 3.2 * persistence
	var hm := _halo.material_override as StandardMaterial3D
	hm.albedo_color.a = 0.16 * persistence

# --- the instrument -----------------------------------------------------------------

func _build_cart() -> void:
	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(0.9, 0.05, 0.62)
	top.mesh = top_mesh
	top.position = Vector3(0.0, 0.78, 0.0)
	top.material_override = _matte_mat(Color(0.30, 0.19, 0.10), 0.85)
	add_child(top)
	for sx in [-0.38, 0.38]:
		for sz in [-0.24, 0.24]:
			var leg := MeshInstance3D.new()
			var leg_mesh := CylinderMesh.new()
			leg_mesh.top_radius = 0.02
			leg_mesh.bottom_radius = 0.02
			leg_mesh.height = 0.76
			leg.mesh = leg_mesh
			leg.position = Vector3(sx, 0.38, sz)
			leg.material_override = _steel_mat(Color(0.35, 0.35, 0.38))
			add_child(leg)
	# the cable: from the scope's back, pooling on the floor - power arrives from
	# somewhere older than the exhibit
	var cable := MeshInstance3D.new()
	var cable_mesh := CylinderMesh.new()
	cable_mesh.top_radius = 0.012
	cable_mesh.bottom_radius = 0.012
	cable_mesh.height = 0.85
	cable.mesh = cable_mesh
	cable.position = Vector3(-0.32, 0.42, -0.3)
	cable.rotation.z = 0.28
	cable.material_override = _matte_mat(Color(0.08, 0.08, 0.09), 0.7)
	add_child(cable)
	var coil := MeshInstance3D.new()
	var coil_mesh := TorusMesh.new()
	coil_mesh.inner_radius = 0.07
	coil_mesh.outer_radius = 0.095
	coil.mesh = coil_mesh
	coil.position = Vector3(-0.44, 0.02, -0.32)
	coil.material_override = _matte_mat(Color(0.08, 0.08, 0.09), 0.7)
	add_child(coil)

func _build_scope() -> void:
	# bakelite body, rounded era, tilted slightly up toward the viewer
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.56, 0.44, 0.5)
	body.mesh = body_mesh
	body.position = Vector3(0.0, 1.03, 0.0)
	body.rotation.x = deg_to_rad(-6.0)
	body.material_override = _matte_mat(Color(0.16, 0.14, 0.13), 0.6)
	add_child(body)
	# the round face: a dark ring bezel and the glass, near-black with green depth
	var bezel := MeshInstance3D.new()
	var bezel_mesh := TorusMesh.new()
	bezel_mesh.inner_radius = 0.155
	bezel_mesh.outer_radius = 0.185
	bezel.mesh = bezel_mesh
	bezel.rotation.x = PI * 0.5 - deg_to_rad(6.0)
	bezel.position = Vector3(0.0, 1.05, 0.262)
	bezel.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(bezel)
	var glass := MeshInstance3D.new()
	var glass_mesh := CylinderMesh.new()
	glass_mesh.top_radius = 0.16
	glass_mesh.bottom_radius = 0.16
	glass_mesh.height = 0.012
	glass.mesh = glass_mesh
	glass.rotation.x = PI * 0.5 - deg_to_rad(6.0)
	glass.position = Vector3(0.0, 1.05, 0.258)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.02, 0.05, 0.03)
	gm.roughness = 0.12
	gm.metallic = 0.1
	glass.material_override = gm
	add_child(glass)
	# two brass knobs: INTENSITY and FOCUS, both already answered
	for i in range(2):
		var knob := MeshInstance3D.new()
		var knob_mesh := CylinderMesh.new()
		knob_mesh.top_radius = 0.028
		knob_mesh.bottom_radius = 0.028
		knob_mesh.height = 0.02
		knob.mesh = knob_mesh
		knob.rotation.x = PI * 0.5
		knob.position = Vector3(-0.08 + 0.16 * float(i), 0.86, 0.26)
		knob.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
		add_child(knob)
	# THE DOT - and its persistence halo, both riding just proud of the glass
	var face_normal := Vector3(0.0, sin(deg_to_rad(6.0)), cos(deg_to_rad(6.0)))
	var on_glass := Vector3(dot_pos.x, 1.05 + dot_pos.y, 0.266)
	_halo = MeshInstance3D.new()
	var halo_mesh := SphereMesh.new()
	halo_mesh.radius = 0.028
	halo_mesh.height = 0.02
	_halo.mesh = halo_mesh
	_halo.position = on_glass
	var hm := StandardMaterial3D.new()
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.albedo_color = Color(PHOSPHOR.r, PHOSPHOR.g, PHOSPHOR.b, 0.16)
	hm.emission_enabled = true
	hm.emission = PHOSPHOR
	hm.emission_energy_multiplier = 0.6
	_halo.material_override = hm
	add_child(_halo)
	_dot = MeshInstance3D.new()
	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.008
	dot_mesh.height = 0.016
	_dot.mesh = dot_mesh
	_dot.position = on_glass + face_normal * 0.004
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.02, 0.03, 0.02)
	dm.emission_enabled = true
	dm.emission = PHOSPHOR
	dm.emission_energy_multiplier = 3.2
	_dot.material_override = dm
	add_child(_dot)
	# one soft green light, so the dot is the ROOM's only opinion about light
	var light := OmniLight3D.new()
	light.light_color = PHOSPHOR
	light.light_energy = 0.5
	light.omni_range = 1.6
	light.position = on_glass + Vector3(0.0, 0.0, 0.15)
	add_child(light)

func _build_shroud() -> void:
	# the black velvet backdrop: the artifact brings its own darkness. Velvet is a rim
	# phenomenon (see interactive_point_origin_force) - near-black, rim up.
	var shroud := MeshInstance3D.new()
	var shroud_mesh := BoxMesh.new()
	shroud_mesh.size = Vector3(1.5, 1.9, 0.03)
	shroud.mesh = shroud_mesh
	shroud.position = Vector3(0.0, 0.98, -0.42)
	var vm := StandardMaterial3D.new()
	vm.albedo_color = Color(0.030, 0.026, 0.036)
	vm.roughness = 0.75
	vm.rim_enabled = true
	vm.rim = 0.7
	vm.rim_tint = 0.3
	shroud.material_override = vm
	add_child(shroud)
	var rail := MeshInstance3D.new()
	var rail_mesh := CylinderMesh.new()
	rail_mesh.top_radius = 0.018
	rail_mesh.bottom_radius = 0.018
	rail_mesh.height = 1.6
	rail.mesh = rail_mesh
	rail.rotation.z = PI * 0.5
	rail.position = Vector3(0.0, 1.96, -0.42)
	rail.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(rail)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "PhosphorPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-0.85, 0.24, 0.55)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("FIRST PHOSPHOR - the medium's nativity",
			"Tennis for Two, 1958, on a scope like this; Spacewar's ships were points\nof light in 1962. Here, 'let there be light' and 'first there was a point'\nare one event. It still blinks at the cursor's cadence - waiting for the word.")
