extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name UmbrellaField

## @identity
## lineage: a plot of open umbrellas on tall poles, every one straining down-wind — the
##   lean deepening where the field blows hard, easing where it rests, canopies
##   shivering in proportion. Walk among them and the invisible field becomes weather
##   you can read from the crowd.
## essence: a vector field is a function from place to push: F(x,z). Each umbrella
##   samples the field where it stands and wears the answer as posture — direction as
##   lean azimuth, magnitude as lean depth and flutter. Sixteen samplers make the
##   function legible the way sixteen windsocks make a runway's wind legible.
## truth: force is a place before it is an event. Stand anywhere in the plot and the
##   nearest umbrella is already telling you what would happen to you there.
##
## The 2026-08-27 forces brief: rung 5 closes the loop — "a force you STAND INSIDE,
## which is rung 1's arrow with the walker put inside it." Calder-palette canopies,
## because the gallery is one family.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const PALETTE := [Color(0.78, 0.16, 0.12), Color(0.92, 0.75, 0.14), Color(0.13, 0.30, 0.62), Color(0.10, 0.10, 0.11), Color(0.88, 0.86, 0.82)]

@export var seed: int = 13
@export_range(2, 6) var rows: int = 4
@export var pitch: float = 1.6         # umbrella spacing, m — plot = (rows-1)*pitch square
@export var pole_h: float = 2.3
## Peak lean, radians. 0.42 (~24 deg) at magnitude 1.0 — umbrellas strain, never spill.
@export var lean: float = 0.42
## The field itself: one broad rotation across the plot plus a standing wobble. kx/kz
## bend the direction with position so neighbouring umbrellas disagree legibly.
## WIND - HOW LOUD THE FIELD SPEAKS. `whisper` leans 10 deg at full magnitude,
## `shipped` 24, `gale` 37 - the same field, spoken at three volumes. (Axis derived
## 2026-08-27.)
@export_enum("whisper", "shipped", "gale") var wind: String = "shipped"
@export var field_kx: float = 0.35
@export var field_kz: float = 0.55

var _umbrellas: Array = []             # {tilt: Node3D, canopy: Node3D, mag: float, phase: float}

func _ready() -> void:
	_rng.seed = seed
	match wind:
		"whisper":
			lean = 0.18
		"gale":
			lean = 0.65
		_:
			pass                     # shipped: lean keeps its export, default 0.42
	_build_plot()
	_build_umbrellas()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "rows", "pitch", "lean"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(_delta: float) -> void:
	# Flutter: a shiver on top of the held lean, amplitude bought by local magnitude.
	# The posture is the vector; the flutter only says the vector is alive.
	var t := float(Time.get_ticks_msec()) / 1000.0
	for u in _umbrellas:
		var canopy: Node3D = u["canopy"]
		if is_instance_valid(canopy):
			var shiver: float = u["mag"] * 0.045
			canopy.rotation.x = sin(t * 7.0 + u["phase"]) * shiver
			canopy.rotation.z = cos(t * 5.3 + u["phase"] * 1.7) * shiver

# --- the field ----------------------------------------------------------------------

## Direction (radians) and magnitude (0..1) of the wind at plot position (x, z).
## Smooth on purpose: a field the umbrellas can make legible, not turbulence.
func _field_at(x: float, z: float) -> Vector2:
	var dir := 0.9 + field_kx * x + field_kz * z + 0.35 * sin(x * 0.9 + z * 0.6)
	var mag := 0.35 + 0.65 * (0.5 + 0.5 * sin(x * 0.7 - z * 0.8 + 1.3))
	return Vector2(dir, clamp(mag, 0.0, 1.0))

func _build_plot() -> void:
	var half := (float(rows) - 1.0) * pitch * 0.5
	var ground := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(half * 2.0 + 1.2, 0.08, half * 2.0 + 1.2)
	ground.mesh = ground_mesh
	ground.position = Vector3(0.0, 0.04, 0.0)
	ground.material_override = _matte_mat(Color(0.14, 0.15, 0.14), 0.95)
	add_child(ground)

func _build_umbrellas() -> void:
	var half := (float(rows) - 1.0) * pitch * 0.5
	var idx := 0
	for i in range(rows):
		for j in range(rows):
			var x := float(i) * pitch - half
			var z := float(j) * pitch - half
			var f := _field_at(x, z)
			_build_umbrella(Vector3(x, 0.08, z), f.x, f.y, idx)
			idx += 1

func _build_umbrella(base: Vector3, wind_dir: float, mag: float, idx: int) -> void:
	# The tilt node leans the WHOLE umbrella down-wind from its foot: azimuth from the
	# field's direction, depth from its magnitude. The posture is the sample.
	var tilt := Node3D.new()
	tilt.position = base
	tilt.rotation.y = -wind_dir
	tilt.rotation.z = -lean * mag
	add_child(tilt)

	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.022
	pole_mesh.bottom_radius = 0.028
	pole_mesh.height = pole_h
	pole.mesh = pole_mesh
	pole.position = Vector3(0.0, pole_h * 0.5, 0.0)
	pole.material_override = _steel_mat(Color(0.30, 0.30, 0.33))
	tilt.add_child(pole)

	var canopy_pivot := Node3D.new()
	canopy_pivot.position = Vector3(0.0, pole_h, 0.0)
	tilt.add_child(canopy_pivot)
	var canopy := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.is_hemisphere = true
	dome.radius = 0.62
	dome.height = 0.34
	canopy.mesh = dome
	canopy.material_override = _matte_mat(PALETTE[idx % PALETTE.size()], 0.7)
	canopy_pivot.add_child(canopy)
	var tip := MeshInstance3D.new()
	var tip_mesh := CylinderMesh.new()
	tip_mesh.top_radius = 0.006
	tip_mesh.bottom_radius = 0.012
	tip_mesh.height = 0.16
	tip.mesh = tip_mesh
	tip.position = Vector3(0.0, 0.40, 0.0)
	tip.material_override = _steel_mat(Color(0.30, 0.30, 0.33))
	canopy_pivot.add_child(tip)
	# eight ribs, because an umbrella without ribs is a lampshade
	for k in range(8):
		var rib := MeshInstance3D.new()
		var rib_mesh := CylinderMesh.new()
		rib_mesh.top_radius = 0.005
		rib_mesh.bottom_radius = 0.005
		rib_mesh.height = 0.60
		rib.mesh = rib_mesh
		var ang := TAU * float(k) / 8.0
		rib.position = Vector3(cos(ang) * 0.30, 0.10, sin(ang) * 0.30)
		rib.rotation = Vector3(cos(ang) * 1.25, 0.0, -sin(ang) * 1.25)
		rib.material_override = _steel_mat(Color(0.30, 0.30, 0.33))
		canopy_pivot.add_child(rib)

	_umbrellas.append({
		"tilt": tilt,
		"canopy": canopy_pivot,
		"mag": mag,
		"phase": _rng.randf_range(0.0, TAU),
	})

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var half := (float(rows) - 1.0) * pitch * 0.5
	var ts := TextScreenScript.new()
	ts.name = "FieldPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-half - 0.5, 0.24, half + 0.4)
	ts.rotation.y = deg_to_rad(40.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("UMBRELLA FIELD",
			"A field is a force with an address: F(x,z). Every umbrella samples the wind\nwhere it stands and wears the answer - lean is direction, depth and shiver are\nmagnitude. Stand anywhere: the nearest umbrella already knows what happens there.")
