extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name HueCarousel

## @identity
## lineage: the color taxonomy's rung 3 — a fairground carousel whose canopy IS the hue
##   wheel. Twelve seats hang from twelve wedges, each painted from_hsv(i/12, ...);
##   an inner ring of six seats sits closer to the pole at low saturation, and the pole
##   itself is the value dimmer, white at the crown fading to black at the base.
## essence: HSV is the same triple through human knobs — hue is where the wheel points,
##   saturation is how far out you sit, value is the house lights. The carousel turns
##   slowly forever, which is what hue does: 1.0 arrives back at 0.0.
## truth: Color.from_hsv(h, s, v) — the second door into the same room. Ride the rim
##   for saturation; sit near the pole and every hue is nearly the same grey.
##
## The 2026-08-27 color taxonomy (doc/COLOR_TAXONOMY.md), rung 3 of 12.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 23
@export var radius: float = 1.7
@export var spin: float = 0.06          # rad/s — hue drifting through the room
@export var canopy_y: float = 2.5

var _rotor: Node3D

func _ready() -> void:
	_rng.seed = seed
	_build_pole()
	_build_rotor()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "radius", "spin"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	_rotor.rotation.y += spin * delta

# --- the pole: value, crown to base -------------------------------------------------

func _build_pole() -> void:
	# five stacked drums, white at the top to near-black at the floor — the V slider
	# stood upright and made structural
	for i in range(5):
		var v := 1.0 - float(i) / 4.0 * 0.92
		var drum := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.12
		dm.bottom_radius = 0.12
		dm.height = canopy_y / 5.0
		drum.mesh = dm
		drum.position = Vector3(0.0, canopy_y / 5.0 * (float(i) + 0.5), 0.0)
		drum.material_override = _matte_mat(Color(v, v, v), 0.6)
		add_child(drum)
	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = radius + 0.25
	bm.bottom_radius = radius + 0.35
	bm.height = 0.12
	base.mesh = bm
	base.position = Vector3(0.0, 0.06, 0.0)
	base.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
	add_child(base)

# --- the rotor: canopy wedges and hanging seats -------------------------------------

func _build_rotor() -> void:
	_rotor = Node3D.new()
	add_child(_rotor)
	for i in range(12):
		var h := float(i) / 12.0
		var ang := TAU * h
		var full := Color.from_hsv(h, 0.95, 1.0)
		# canopy wedge: a thin box laid along the radius, hue-stepped
		var wedge := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(radius * 0.94, 0.05, radius * 0.5)
		wedge.mesh = wm
		wedge.position = Vector3(cos(ang) * radius * 0.5, canopy_y, sin(ang) * radius * 0.5)
		wedge.rotation.y = -ang
		wedge.material_override = _glow_mat(full, 0.7)
		_rotor.add_child(wedge)
		# outer seat, full saturation, on two chains
		_hang_seat(ang, radius * 0.92, Color.from_hsv(h, 0.95, 0.95), 0.85)
		# inner seat every second wedge, close to the pole, starved of saturation
		if i % 2 == 0:
			_hang_seat(ang + TAU / 24.0, radius * 0.38, Color.from_hsv(h, 0.22, 0.95), 0.55)

func _hang_seat(ang: float, r: float, tint: Color, drop: float) -> void:
	var x := cos(ang) * r
	var z := sin(ang) * r
	var chain_mat := _matte_mat(Color(0.3, 0.3, 0.33), 0.6, 0.7)
	for side in [-0.09, 0.09]:
		var chain := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.004
		cm.bottom_radius = 0.004
		cm.height = drop
		chain.mesh = cm
		chain.position = Vector3(x + cos(ang + PI * 0.5) * side, canopy_y - drop * 0.5, z + sin(ang + PI * 0.5) * side)
		chain.material_override = chain_mat
		_rotor.add_child(chain)
	var seat := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.26, 0.05, 0.2)
	seat.mesh = sm
	seat.position = Vector3(x, canopy_y - drop, z)
	seat.rotation.y = -ang
	seat.material_override = _matte_mat(tint, 0.55)
	_rotor.add_child(seat)
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.26, 0.16, 0.03)
	back.mesh = bm
	back.position = Vector3(x - cos(ang) * 0.085, canopy_y - drop + 0.1, z - sin(ang) * 0.085)
	back.rotation.y = -ang
	back.material_override = _matte_mat(tint, 0.55)
	_rotor.add_child(back)

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "CarouselPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-radius - 0.45, 0.24, radius * 0.5)
	ts.rotation.y = deg_to_rad(40.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("HUE CAROUSEL",
			"from_hsv: hue is where the wheel points, saturation is how far out you sit\n(the inner seats are nearly grey), value is the pole - white crown, dark floor.\nIt never stops, because 1.0 is 0.0.")
