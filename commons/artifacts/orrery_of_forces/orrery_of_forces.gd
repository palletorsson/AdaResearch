extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name OrreryOfForces

## @identity
## lineage: the forces SUPER OBJECT — the whole ladder folded into one brass machine.
##   A table orrery: an emissive sun on the column (mass), a planet arm circling it
##   with a moonlet circling the planet (orbit, n-body), a pendulum outrigger keeping
##   its real period, a spring bob breathing Hooke's time, a paused parabola of beads
##   from a little cannon to a cup (the fountain, quoted), a miniature cradle at the
##   rim with one ball forever lifted (momentum, poised), and a crown of eight vanes
##   all leaning tangent (the field). Brass rung-labels at every station.
## essence: an orrery was always this — the laws working a machine so the laws can be
##   WATCHED. The pendulum and the spring run their true equations; the orbits run as
##   an orrery's do, by clockwork that admits it (the placard says which is which).
##   One object, every rung, no diagram anywhere.
## truth: the whole ladder in one machine — position, velocity, force, orbit, spring,
##   swing, throw, strike, field. F = ma, performed as furniture.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 61
@export var orbit_rate: float = 0.35     # planet rad/s; the moon runs 3.7x
@export var pend_len: float = 0.6

var _planet_arm: Node3D
var _moon_arm: Node3D
var _pend: Node3D
var _pend_theta := 0.5
var _pend_omega := 0.0
var _spring_bob: Node3D
var _spring_coil: Node3D

func _ready() -> void:
	_rng.seed = seed
	_build_table()
	_build_sun_and_orbits()
	_build_pendulum()
	_build_spring()
	_build_parabola()
	_build_cradle()
	_build_field_crown()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "orbit_rate"]:
		if config_data.has(key):
			set(key, config_data[key])

func _physics_process(delta: float) -> void:
	_planet_arm.rotation.y += orbit_rate * delta
	_moon_arm.rotation.y += orbit_rate * 3.7 * delta
	# the pendulum runs its true equation, undriven and undamped but for a whisper
	var acc := -(9.8 / pend_len) * sin(_pend_theta) - 0.02 * _pend_omega
	_pend_omega += acc * delta
	_pend_theta += _pend_omega * delta
	_pend.rotation.z = _pend_theta
	# Hooke's time: x(t) = A cos(wt), and the coil stretches to follow the bob
	var t := float(Time.get_ticks_msec()) / 1000.0
	var x := 0.14 * cos(t * 3.1)
	_spring_bob.position.y = 1.06 - x
	_spring_coil.scale.y = 1.0 + x * 2.2

func _rung_tag(at: Vector3, txt: String) -> void:
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.13
	tag.position = at
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text(txt, "")

# --- the machine --------------------------------------------------------------------

func _build_table() -> void:
	var top := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 1.5
	tm.bottom_radius = 1.55
	tm.height = 0.1
	top.mesh = tm
	top.position = Vector3(0.0, 0.85, 0.0)
	top.material_override = _matte_mat(Color(0.16, 0.13, 0.11), 0.8)
	add_child(top)
	var leg := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.12
	lm.bottom_radius = 0.3
	lm.height = 0.85
	leg.mesh = lm
	leg.position = Vector3(0.0, 0.425, 0.0)
	leg.material_override = _matte_mat(Color(0.12, 0.11, 0.1), 0.85)
	add_child(leg)
	var column := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.045
	cm.bottom_radius = 0.06
	cm.height = 0.8
	column.mesh = cm
	column.position = Vector3(0.0, 1.3, 0.0)
	column.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(column)

func _build_sun_and_orbits() -> void:
	var sun := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.13
	sm.height = 0.26
	sun.mesh = sm
	sun.position = Vector3(0.0, 1.74, 0.0)
	sun.material_override = _glow_mat(Color(0.98, 0.75, 0.3), 2.4)
	add_child(sun)
	_rung_tag(Vector3(0.28, 1.7, 0.0), "mass")
	_planet_arm = Node3D.new()
	_planet_arm.position = Vector3(0.0, 1.62, 0.0)
	_planet_arm.rotation.y = _rng.randf_range(0.0, TAU)
	add_child(_planet_arm)
	var arm := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(0.9, 0.014, 0.03)
	arm.mesh = am
	arm.position = Vector3(0.45, 0.0, 0.0)
	arm.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	_planet_arm.add_child(arm)
	var planet := MeshInstance3D.new()
	var pm := SphereMesh.new()
	pm.radius = 0.06
	pm.height = 0.12
	planet.mesh = pm
	planet.position = Vector3(0.9, 0.0, 0.0)
	planet.material_override = _matte_mat(Color(0.25, 0.5, 0.85), 0.5)
	_planet_arm.add_child(planet)
	_moon_arm = Node3D.new()
	_moon_arm.position = Vector3(0.9, 0.0, 0.0)
	_planet_arm.add_child(_moon_arm)
	var moon := MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 0.025
	mm.height = 0.05
	moon.mesh = mm
	moon.position = Vector3(0.16, 0.0, 0.0)
	moon.material_override = _matte_mat(Color(0.8, 0.8, 0.82), 0.6)
	_moon_arm.add_child(moon)
	_rung_tag(Vector3(0.0, 0.92, -1.25), "orbit / n-body")

func _build_pendulum() -> void:
	var mast := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.025
	mm.bottom_radius = 0.035
	mm.height = 0.85
	mast.mesh = mm
	mast.position = Vector3(-1.05, 1.325, 0.35)
	mast.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(mast)
	_pend = Node3D.new()
	_pend.position = Vector3(-1.05, 1.75, 0.35)
	add_child(_pend)
	var rod := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.008
	rm.bottom_radius = 0.008
	rm.height = pend_len
	rod.mesh = rm
	rod.position = Vector3(0.0, -pend_len * 0.5, 0.0)
	rod.material_override = _steel_mat(Color(0.4, 0.38, 0.35))
	_pend.add_child(rod)
	var bob := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.055
	bm.height = 0.11
	bob.mesh = bm
	bob.position = Vector3(0.0, -pend_len, 0.0)
	bob.material_override = _glow_mat(Color(0.85, 0.3, 0.25), 0.8)
	_pend.add_child(bob)
	_rung_tag(Vector3(-1.35, 0.92, 0.7), "period")

func _build_spring() -> void:
	var gallows := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.03, 0.5, 0.03)
	gallows.mesh = gm
	gallows.position = Vector3(1.05, 1.15, 0.45)
	gallows.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(gallows)
	_spring_coil = Node3D.new()
	_spring_coil.position = Vector3(1.05, 1.4, 0.45)
	add_child(_spring_coil)
	for i in range(6):
		var ring := MeshInstance3D.new()
		var rm := TorusMesh.new()
		rm.inner_radius = 0.028
		rm.outer_radius = 0.05
		ring.mesh = rm
		ring.position = Vector3(0.0, -0.05 * float(i) - 0.03, 0.0)
		ring.material_override = _steel_mat(Color(0.6, 0.62, 0.66))
		_spring_coil.add_child(ring)
	_spring_bob = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.11, 0.11, 0.11)
	_spring_bob.mesh = bm
	_spring_bob.position = Vector3(1.05, 1.06, 0.45)
	_spring_bob.material_override = _matte_mat(Color(0.72, 0.52, 0.95), 0.6)
	add_child(_spring_bob)
	_rung_tag(Vector3(1.35, 0.92, 0.75), "Hooke")

func _build_parabola() -> void:
	# the fountain, quoted at desk scale: a cannon, seven frozen beads, a cup
	var cannon := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.03
	cm.bottom_radius = 0.045
	cm.height = 0.16
	cannon.mesh = cm
	cannon.position = Vector3(-0.55, 0.96, -0.85)
	cannon.rotation.z = deg_to_rad(-55.0)
	cannon.material_override = _steel_mat(Color(0.35, 0.33, 0.3))
	add_child(cannon)
	var v0 := Vector3(0.75, 1.35, 0.0)
	for k in range(1, 8):
		var t := 0.12 * float(k)
		var pos := Vector3(-0.55, 1.0, -0.85) + v0 * t + Vector3(0.0, -0.5 * 9.8 * t * t, 0.0)
		var bead := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.022
		sm.height = 0.044
		bead.mesh = sm
		bead.position = pos
		bead.material_override = _glow_mat(Color(0.95, 0.85, 0.4), 1.2)
		add_child(bead)
	var cup := MeshInstance3D.new()
	var um := CylinderMesh.new()
	um.top_radius = 0.07
	um.bottom_radius = 0.05
	um.height = 0.08
	cup.mesh = um
	cup.position = Vector3(0.12, 0.94, -0.85)
	cup.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(cup)
	_rung_tag(Vector3(-0.2, 0.92, -1.15), "throw / g")

func _build_cradle() -> void:
	# momentum, poised: five tiny balls, the end one held lifted forever
	var base := Vector3(0.85, 0.9, -0.55)
	for i in range(5):
		var x := base.x + 0.05 * float(i)
		var lifted := i == 4
		var ang := deg_to_rad(-38.0) if lifted else 0.0
		var pivot := Vector3(x, base.y + 0.22, base.z)
		var pos := pivot + Vector3(sin(ang) * 0.18, -cos(ang) * 0.18, 0.0)
		var wire := MeshInstance3D.new()
		var wm := CylinderMesh.new()
		wm.top_radius = 0.003
		wm.bottom_radius = 0.003
		wm.height = 0.18
		wire.mesh = wm
		wire.position = (pivot + pos) * 0.5
		wire.rotation.z = ang
		wire.material_override = _steel_mat(Color(0.5, 0.5, 0.54))
		add_child(wire)
		var ball := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.024
		sm.height = 0.048
		ball.mesh = sm
		ball.position = pos
		ball.material_override = _steel_mat(Color(0.75, 0.77, 0.82))
		add_child(ball)
	var bar := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.32, 0.015, 0.015)
	bar.mesh = bm
	bar.position = Vector3(base.x + 0.1, base.y + 0.23, base.z)
	bar.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(bar)
	_rung_tag(Vector3(1.15, 0.92, -0.85), "momentum")

func _build_field_crown() -> void:
	# eight vanes around the sun, all tangent: the field you could stand inside,
	# shrunk to a crown
	for i in range(8):
		var ang := TAU * float(i) / 8.0
		var at := Vector3(cos(ang) * 0.45, 1.95, sin(ang) * 0.45)
		var vane := MeshInstance3D.new()
		var vm := PrismMesh.new()
		vm.size = Vector3(0.09, 0.02, 0.13)
		vane.mesh = vm
		vane.position = at
		vane.rotation.y = -ang - PI * 0.5
		vane.material_override = _glow_mat(Color.from_hsv(float(i) / 8.0, 0.5, 0.95), 0.8)
		add_child(vane)
	_rung_tag(Vector3(0.0, 2.12, 0.55), "the field")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "OrreryPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-1.55, 0.24, 1.1)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("ORRERY OF FORCES",
			"The whole ladder in one machine: mass, orbit, period, Hooke, throw,\nmomentum, field. The pendulum and spring run their true equations;\nthe orbits run as an orrery's always did - clockwork that admits it.")
