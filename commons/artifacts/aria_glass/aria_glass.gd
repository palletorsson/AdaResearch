extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AriaGlass

## @identity
## lineage: the Resonance hero — a wine glass on a plinth, a gramophone horn aimed at
##   it, and the moment held forever: the bowl bursting into a ring of suspended
##   shards. On the music stand, the only note that could do it. Every other note in
##   the world was sung at this glass and the glass ignored them all.
## essence: resonance - a thing answers only its own frequency. The glass has one
##   note it cannot refuse; matched, each pass of the wave arrives exactly in time
##   with the swing already there, and the amplitude climbs until the material gives.
## truth: the horn is not loud. It is CORRECT. Correctness, repeated in phase, is the
##   force multiplier - which is why the shards hang in a ring and not a heap.
##
## The 2026-08-29 category-heroes pass, wavefunctions.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 11
## How far the shatter has progressed outward, 0..1.
@export var burst: float = 0.55

func _ready() -> void:
	_rng.seed = seed
	_build_plinth()
	_build_glass()
	_build_horn()
	_build_stand()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "burst"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_plinth() -> void:
	add_child(_box(Vector3(0.0, 0.5, 0.0), Vector3(0.5, 1.0, 0.5), _matte_mat(Color(0.88, 0.87, 0.84), 0.85)))
	add_child(_box(Vector3(0.0, 1.02, 0.0), Vector3(0.56, 0.04, 0.56), _matte_mat(Color(0.8, 0.79, 0.76), 0.8)))

func _build_glass() -> void:
	var base_y := 1.04
	var glass := _glass_mat(Color(0.82, 0.9, 0.95), 0.30)
	# foot and stem survive - only the bowl answered the note
	add_child(_cylinder(Vector3(0.0, base_y + 0.012, 0.0), 0.09, 0.025, glass))
	add_child(_cylinder(Vector3(0.0, base_y + 0.1, 0.0), 0.014, 0.16, glass))
	add_child(_sphere(Vector3(0.0, base_y + 0.19, 0.0), 0.03, glass))
	# the lowest belt of the bowl still holds its curve
	var bowl_y := base_y + 0.24
	add_child(_cylinder(Vector3(0.0, bowl_y, 0.0), 0.055, 0.05, glass))
	# THE RING OF SHARDS: the bowl wall, let go mid-flight. Height and tilt seeded,
	# radius paid out by burst - a frozen explosion that is also a bell diagram.
	var shards := 16
	for i in range(shards):
		var a := TAU * float(i) / float(shards) + _rng.randf_range(-0.08, 0.08)
		var lift := _rng.randf_range(0.0, 0.16)
		var r := 0.07 + burst * (0.16 + _rng.randf_range(0.0, 0.22))
		var p := Vector3(cos(a) * r, bowl_y + 0.09 + lift + burst * 0.10, sin(a) * r)
		var shard := _box(p, Vector3(0.016, 0.07 + _rng.randf_range(0.0, 0.06), 0.045), _glass_mat(Color(0.85, 0.93, 0.98), 0.45))
		shard.rotation = Vector3(_rng.randf_range(-0.9, 0.9), a, _rng.randf_range(-0.9, 0.9))
		add_child(shard)
	# the resonant ring made visible: one glowing hoop at the rim the bowl had
	add_child(_torus(Vector3(0.0, bowl_y + 0.10, 0.0), 0.085, 0.006, _glow_mat(Color(0.95, 0.8, 0.4), 2.0)))

func _build_horn() -> void:
	# gramophone horn on its own stand, mouth aimed at the glass
	var base := Vector3(1.05, 0.0, -0.12)
	add_child(_box(base + Vector3(0.0, 0.35, 0.0), Vector3(0.42, 0.7, 0.42), _matte_mat(Color(0.32, 0.22, 0.14), 0.75)))
	add_child(_box(base + Vector3(0.0, 0.72, 0.0), Vector3(0.46, 0.05, 0.46), _matte_mat(Color(0.4, 0.28, 0.17), 0.7)))
	var brass := _steel_mat(Color(0.74, 0.6, 0.28))
	# neck: three segments curving up and toward the glass
	var p0 := base + Vector3(0.0, 0.76, 0.0)
	var p1 := base + Vector3(-0.12, 0.9, 0.03)
	var p2 := base + Vector3(-0.3, 1.02, 0.06)
	add_child(_cylinder_between(p0, p1, 0.03, brass))
	add_child(_cylinder_between(p1, p2, 0.035, brass))
	# the bell: a cone opening toward the glass
	var bell := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 0.3
	cone.height = 0.42
	bell.mesh = cone
	bell.material_override = brass
	var dir := (Vector3(0.0, 1.35, 0.0) - p2).normalized()
	bell.transform = Transform3D(_basis_y_to(-dir), p2 + dir * 0.24)
	add_child(bell)
	# the note travelling: faint expanding rings between horn and glass
	for i in range(4):
		var u := (float(i) + 0.7) / 4.6
		var q := (p2 + dir * 0.4).lerp(Vector3(0.0, 1.33, 0.0), u)
		var ring := _torus(q, 0.05 + u * 0.16, 0.004, _glass_mat(Color(0.95, 0.85, 0.5), 0.5))
		ring.rotation.z = PI * 0.5
		add_child(ring)

func _build_stand() -> void:
	# the music stand holding the card with the one correct note
	var base := Vector3(0.62, 0.0, 0.58)
	add_child(_cylinder(base + Vector3(0.0, 0.5, 0.0), 0.015, 1.0, _matte_mat(Color(0.15, 0.15, 0.18), 0.5, 0.5)))
	for i in range(3):
		var a := TAU * float(i) / 3.0 + 0.5
		add_child(_cylinder_between(base + Vector3(0.0, 0.06, 0.0), base + Vector3(cos(a) * 0.16, 0.0, sin(a) * 0.16), 0.012, _matte_mat(Color(0.15, 0.15, 0.18), 0.5, 0.5)))
	var card := _box(base + Vector3(0.0, 1.12, 0.0), Vector3(0.3, 0.22, 0.015), _matte_mat(Color(0.93, 0.9, 0.82), 0.9))
	card.rotation.x = -0.25
	add_child(card)
	var l := _billboard_label("A#4 · 466 Hz", base + Vector3(0.0, 1.13, 0.03), 13, Color(0.25, 0.2, 0.12))
	l.no_depth_test = false
	add_child(l)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "AriaPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-0.55, 0.24, 0.75)
	ts.rotation.y = deg_to_rad(14.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("ARIA GLASS - resonance",
			"Every other note in the world was sung at this glass, and the glass\nignored them all. The horn is not loud - it is CORRECT, and correctness\nrepeated in phase climbs until the material gives. The shards hang in a ring.")
