extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ShadowCarousel

## @identity
## lineage: the Circle hero — a fairground carousel with one lamp beside it and one
##   dark screen behind it. The horses go round in the only motion the engine owns;
##   their shadows on the screen rise and fall, and the trace of one full revolution
##   is painted there as a curve nobody drew: the sine.
## essence: sin(t) is the vertical shadow of uniform rotation. Nothing on the screen
##   moves in a circle - the circle is offstage, and what reaches the wall is only its
##   height. Everything after this room is costume on that shadow.
## truth: the carousel does one thing. The wall sees half of it. That half is the wave.
##
## The 2026-08-29 category-heroes pass, wavefunctions.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 5
@export var ride_radius: float = 0.85
## Phase of the ride at the frozen/live moment, radians.
@export var phase: float = 0.9
@export var spin_speed: float = 0.35

var _ride: Node3D

func _ready() -> void:
	_rng.seed = seed
	_build_carousel()
	_build_lamp()
	_build_screen()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "ride_radius", "phase", "spin_speed"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	if _ride:
		_ride.rotation.y += spin_speed * delta

func _build_carousel() -> void:
	# platform and canopy: the machine of uniform rotation
	var plat := _cylinder(Vector3(0.0, 0.06, 0.0), ride_radius + 0.25, 0.12, _matte_mat(Color(0.62, 0.14, 0.18), 0.6))
	add_child(plat)
	var pole := _cylinder(Vector3(0.0, 0.95, 0.0), 0.05, 1.8, _steel_mat(Color(0.75, 0.65, 0.35)))
	add_child(pole)
	var canopy := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.02
	cone.bottom_radius = ride_radius + 0.3
	cone.height = 0.42
	canopy.mesh = cone
	canopy.position = Vector3(0.0, 1.95, 0.0)
	canopy.material_override = _matte_mat(Color(0.92, 0.84, 0.55), 0.7)
	add_child(canopy)
	add_child(_torus(Vector3(0.0, 1.76, 0.0), ride_radius + 0.28, 0.025, _steel_mat(Color(0.7, 0.6, 0.3))))
	# the ride: four horses on poles, one painted as the LEAD (its shadow is traced)
	_ride = Node3D.new()
	_ride.name = "Ride"
	_ride.rotation.y = phase
	add_child(_ride)
	for i in range(4):
		var a := TAU * float(i) / 4.0
		var horse := _horse(Color(0.85, 0.82, 0.78) if i > 0 else Color(0.82, 0.30, 0.20))
		horse.position = Vector3(cos(a) * ride_radius, 0.55 + 0.12 * sin(a * 2.0), sin(a) * ride_radius)
		horse.rotation.y = -a + PI * 0.5
		_ride.add_child(horse)
		var hp := _cylinder_between(Vector3(cos(a) * ride_radius, 0.12, sin(a) * ride_radius),
			Vector3(cos(a) * ride_radius, 1.74, sin(a) * ride_radius), 0.018, _steel_mat(Color(0.72, 0.62, 0.32)))
		_ride.add_child(hp)

func _horse(col: Color) -> Node3D:
	var h := Node3D.new()
	h.add_child(_box(Vector3(0.0, 0.0, 0.0), Vector3(0.34, 0.16, 0.12), _matte_mat(col, 0.55)))
	var neck := _box(Vector3(0.16, 0.13, 0.0), Vector3(0.09, 0.2, 0.09), _matte_mat(col, 0.55))
	neck.rotation.z = -0.5
	h.add_child(neck)
	h.add_child(_box(Vector3(0.24, 0.22, 0.0), Vector3(0.14, 0.08, 0.08), _matte_mat(col * 0.92, 0.55)))
	for sx in [-0.12, 0.12]:
		for sz in [-0.045, 0.045]:
			h.add_child(_box(Vector3(sx, -0.14, sz), Vector3(0.035, 0.14, 0.035), _matte_mat(col * 0.85, 0.6)))
	return h

func _build_lamp() -> void:
	# one lamp, off to the side: the projector of the definition
	var base := Vector3(ride_radius + 1.15, 0.0, 0.0)
	add_child(_cylinder(base + Vector3(0.0, 0.5, 0.0), 0.035, 1.0, _matte_mat(Color(0.2, 0.2, 0.22), 0.5, 0.6)))
	add_child(_cylinder(base + Vector3(0.0, 0.02, 0.0), 0.16, 0.05, _matte_mat(Color(0.2, 0.2, 0.22), 0.5, 0.6)))
	var head := _sphere(base + Vector3(-0.06, 1.05, 0.0), 0.11, _glow_mat(Color(1.0, 0.93, 0.72), 2.4))
	add_child(head)
	var lamp := OmniLight3D.new()
	lamp.position = base + Vector3(-0.1, 1.05, 0.0)
	lamp.light_energy = 1.6
	lamp.light_color = Color(1.0, 0.93, 0.75)
	lamp.omni_range = 5.0
	add_child(lamp)

func _build_screen() -> void:
	# the dark screen on the far side, carrying one revolution of shadow-heights:
	# the sine, drawn by the ride itself
	var sx := -(ride_radius + 1.25)
	var screen := _box(Vector3(sx, 1.05, 0.0), Vector3(0.06, 1.5, 2.4), _matte_mat(Color(0.10, 0.10, 0.13), 0.9))
	add_child(screen)
	add_child(_box(Vector3(sx, 0.22, 0.0), Vector3(0.16, 0.44, 0.5), _matte_mat(Color(0.16, 0.16, 0.2), 0.8)))
	var n := 26
	var pts: Array[Vector3] = []
	for i in range(n + 1):
		var u := float(i) / float(n)
		var z := -1.05 + 2.1 * u
		var y := 1.05 + 0.55 * sin(u * TAU + phase)
		pts.append(Vector3(sx + 0.05, y, z))
	for i in range(n):
		add_child(_cylinder_between(pts[i], pts[i + 1], 0.012, _glow_mat(Color(0.95, 0.85, 0.45), 1.6)))
	# the CURRENT shadow: one bright horse-silhouette dot, plus the projection dash
	# from the lead horse across the ride to the wall - the definition as a string
	var lead := Vector3(cos(phase) * ride_radius, 1.05 + 0.55 * sin(phase), sin(phase) * ride_radius)
	var dot := _sphere(Vector3(sx + 0.06, 1.05 + 0.55 * sin(phase), sin(phase) * ride_radius * 0.0 - 1.05), 0.05, _glow_mat(Color(1.0, 0.5, 0.3), 2.6))
	dot.position.z = -1.05
	add_child(dot)
	add_child(_dashed(lead, Vector3(sx + 0.06, lead.y, -1.05), 0.008, _glow_mat(Color(1.0, 0.6, 0.4), 1.2)))

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "CarouselPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(0.9, 0.24, 1.55)
	ts.rotation.y = deg_to_rad(12.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("SHADOW CAROUSEL - sin(t)",
			"The carousel does one thing: it goes round. The lamp asks only how HIGH\neach horse is, and writes the answers on the wall in a line.\nThat line is the sine. The circle is offstage; the wave is its shadow.")
