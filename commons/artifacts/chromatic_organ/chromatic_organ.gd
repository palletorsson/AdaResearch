extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ChromaticOrgan

## @identity
## lineage: the color SUPER OBJECT — the twelve-rung ladder as one cathedral organ.
##   A swinging bulb hangs above the case (no light, no color). Three great pipes
##   labelled R, G, B pour their channels into a glowing mix basin (the triple).
##   The facade ranks run in hue order (the second door): one rank matte (skin),
##   one of pure emission (glow), one of glass (through), one glitched sideways
##   (the screen's flesh). A stage lamp sweeps the facade cycling three colours,
##   re-dealing every pipe's seen-colour as it passes (multiplication). Up the case
##   sides run the two roads — the RGB stripe mudding mid-way, the HSV stripe
##   saturated. Two stop-knobs drift locked in complement (the chord). The manual's
##   grey keys sit on warm and cool felt and refuse to match (the ground). And the
##   whole instrument stands in its own halo of fog-light (the room).
## essence: an organ is already the right body — one instrument, many ranks, each
##   rank one voice. Here every rank is a rung, and the swell is the whole ladder
##   sounding at once.
## truth: color is perception, not physics — twelve rungs, one instrument.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 62
@export var sweep_rate: float = 0.22    # stage lamp passes per second across the facade

var _bulb_arm: Node3D
var _theta := 0.35
var _omega := 0.0
var _lamp: SpotLight3D
var _lamp_house: MeshInstance3D
var _knob_a: StandardMaterial3D
var _knob_b: StandardMaterial3D
const LAMP_COLORS := [Color(1.0, 0.93, 0.78), Color(0.3, 0.5, 1.0), Color(1.0, 0.15, 0.1)]

func _ready() -> void:
	_rng.seed = seed
	_build_case()
	_build_pipes()
	_build_manual()
	_build_bulb()
	_build_sweep_lamp()
	_build_halo()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "sweep_rate"]:
		if config_data.has(key):
			set(key, config_data[key])

func _physics_process(delta: float) -> void:
	var acc := -(9.8 / 0.7) * sin(_theta) - 0.06 * _omega
	_omega += acc * delta
	_theta += _omega * delta
	_bulb_arm.rotation.z = _theta

func _process(_delta: float) -> void:
	var t := float(Time.get_ticks_msec()) / 1000.0
	# the stage lamp: sweeping x across the facade, cycling its colour per pass
	var phase := t * sweep_rate
	var x := sin(phase * TAU) * 1.35
	var which := int(floor(phase * 2.0)) % LAMP_COLORS.size()
	_lamp.position.x = x
	_lamp_house.position.x = x
	if _lamp.light_color != LAMP_COLORS[which]:
		_lamp.light_color = LAMP_COLORS[which]
		var hm: StandardMaterial3D = _lamp_house.material_override
		hm.emission = LAMP_COLORS[which]
	# the chord: two stop-knobs forever opposite on the wheel
	var h := fmod(t * 0.02, 1.0)
	_knob_a.albedo_color = Color.from_hsv(h, 0.8, 0.9)
	_knob_a.emission = _knob_a.albedo_color
	_knob_b.albedo_color = Color.from_hsv(fmod(h + 0.5, 1.0), 0.8, 0.9)
	_knob_b.emission = _knob_b.albedo_color

# --- the case -----------------------------------------------------------------------

func _build_case() -> void:
	var wood := _matte_mat(Color(0.1, 0.08, 0.08), 0.85)
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.0, 2.6, 0.16)
	back.mesh = bm
	back.position = Vector3(0.0, 1.5, -0.35)
	back.material_override = wood
	add_child(back)
	for sx in [-1.0, 1.0]:
		var tower := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.34, 2.9, 0.5)
		tower.mesh = tm
		tower.position = Vector3(sx * 1.5, 1.45, -0.2)
		tower.material_override = wood
		add_child(tower)
		# the two roads, one per side: 14 steps floor to crown
		for k in range(14):
			var t := (float(k) + 0.5) / 14.0
			var c: Color
			if sx < 0.0:
				c = Color(0.0, 0.6, 0.8).lerp(Color(0.95, 0.55, 0.1), t)      # RGB: mud mid-way
			else:
				c = Color.from_hsv(lerpf(0.53, 0.09, t), 0.92, 0.9)           # HSV: the wheel
			var step := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(0.3, 2.6 / 14.0 * 0.9, 0.03)
			step.mesh = sm
			step.position = Vector3(sx * 1.5, 0.25 + 2.6 * t, 0.06)
			step.material_override = _glow_mat(c, 0.45)
			add_child(step)

func _build_pipes() -> void:
	# the facade: twelve hue-ordered pipes in four ranks of dress — matte skin,
	# pure glow, glass through, and one glitched
	var glass_base := StandardMaterial3D.new()
	glass_base.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_base.roughness = 0.05
	for i in range(12):
		var h := float(i) / 12.0
		var x := -1.15 + 2.3 * float(i) / 11.0
		var height := 1.15 + 0.75 * absf(sin(float(i) * 0.9 + 1.2))
		var pipe := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.075
		pm.bottom_radius = 0.075
		pm.height = height
		pipe.mesh = pm
		var mode := i % 4
		var y0 := 1.05
		var tint := Color.from_hsv(h, 0.85, 0.9)
		match mode:
			0:
				pipe.material_override = _matte_mat(tint, 0.6)                # skin
			1:
				var m := StandardMaterial3D.new()
				m.albedo_color = Color(0.02, 0.02, 0.02)
				m.emission_enabled = true
				m.emission = tint
				m.emission_energy_multiplier = 1.8 if emissive else 0.6
				pipe.material_override = m                                    # glow
			2:
				var g := glass_base.duplicate()
				g.albedo_color = Color(tint.r, tint.g, tint.b, 0.28)
				pipe.material_override = g                                    # through
			_:
				pipe.material_override = _matte_mat(tint, 0.6)                # glitched below
		pipe.position = Vector3(x, y0 + height * 0.5, 0.0)
		if mode == 3:
			# the glitch: the pipe sliced, middle third sheared sideways and hue-slipped
			pipe.scale.y = 0.34
			pipe.position.y = y0 + height * 0.17
			for s in range(2):
				var slice := MeshInstance3D.new()
				var sm := CylinderMesh.new()
				sm.top_radius = 0.075
				sm.bottom_radius = 0.075
				sm.height = height * 0.31
				slice.mesh = sm
				var off := 0.05 if s == 0 else -0.03
				slice.position = Vector3(x + off, y0 + height * (0.5 + 0.31 * float(s)), 0.0)
				slice.material_override = _matte_mat(Color.from_hsv(fmod(h + 0.33 * float(s + 1), 1.0), 0.85, 0.9), 0.6)
				add_child(slice)
		add_child(pipe)
	# the three great channel pipes and their basin
	var labels := ["R", "G", "B"]
	var tints := [Color(1, 0.12, 0.1), Color(0.15, 1, 0.2), Color(0.2, 0.35, 1)]
	for i in range(3):
		var x := -0.5 + 0.5 * float(i)
		var great := MeshInstance3D.new()
		var gm := CylinderMesh.new()
		gm.top_radius = 0.11
		gm.bottom_radius = 0.11
		gm.height = 2.2
		great.mesh = gm
		great.position = Vector3(x, 1.75, -0.22)
		var m := _glow_mat(tints[i], 1.1)
		great.material_override = m
		add_child(great)
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.09
		tag.position = Vector3(x, 2.92, -0.1)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text(labels[i], "")
	var basin := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.34
	bm.bottom_radius = 0.28
	bm.height = 0.1
	basin.mesh = bm
	basin.position = Vector3(0.0, 0.98, -0.1)
	basin.material_override = _glow_mat(Color(0.62, 0.55, 0.72), 1.6)
	add_child(basin)

func _build_manual() -> void:
	# grey keys on two felts, warm left and cool right — the same greys refusing
	# to match across the divide
	var shelf := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(1.9, 0.07, 0.42)
	shelf.mesh = sm
	shelf.position = Vector3(0.0, 0.82, 0.32)
	shelf.material_override = _matte_mat(Color(0.1, 0.08, 0.08), 0.85)
	add_child(shelf)
	for half in range(2):
		var felt := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.9, 0.015, 0.36)
		felt.mesh = fm
		felt.position = Vector3(-0.46 + 0.92 * float(half), 0.86, 0.32)
		felt.material_override = _matte_mat(Color(0.55, 0.3, 0.15) if half == 0 else Color(0.15, 0.3, 0.5), 0.9)
		add_child(felt)
		for k in range(7):
			var key := MeshInstance3D.new()
			var km := BoxMesh.new()
			km.size = Vector3(0.1, 0.02, 0.3)
			key.mesh = km
			key.position = Vector3(-0.85 + 0.92 * float(half) + 0.125 * float(k), 0.88, 0.32)
			key.material_override = _matte_mat(Color(0.55, 0.55, 0.55), 0.7)
			add_child(key)
	# the chord: two stop knobs, forever complementary
	_knob_a = _glow_mat(Color(0.9, 0.3, 0.3), 0.9)
	_knob_b = _glow_mat(Color(0.3, 0.9, 0.9), 0.9)
	for i in range(2):
		var knob := MeshInstance3D.new()
		var km := SphereMesh.new()
		km.radius = 0.05
		km.height = 0.1
		knob.mesh = km
		knob.position = Vector3(-1.15 + 2.3 * float(i), 0.95, 0.42)
		knob.material_override = _knob_a if i == 0 else _knob_b
		add_child(knob)

func _build_bulb() -> void:
	var anchor := Node3D.new()
	anchor.position = Vector3(0.0, 3.35, 0.3)
	add_child(anchor)
	_bulb_arm = Node3D.new()
	anchor.add_child(_bulb_arm)
	var cord := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.005
	cm.bottom_radius = 0.005
	cm.height = 0.7
	cord.mesh = cm
	cord.position = Vector3(0.0, -0.35, 0.0)
	cord.material_override = _matte_mat(Color(0.15, 0.14, 0.13), 0.8)
	_bulb_arm.add_child(cord)
	var glass := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.06
	gm.height = 0.12
	glass.mesh = gm
	glass.position = Vector3(0.0, -0.7, 0.0)
	glass.material_override = _glow_mat(Color(1.0, 0.93, 0.78), 2.2)
	_bulb_arm.add_child(glass)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.93, 0.78)
	light.light_energy = 1.6
	light.omni_range = 4.5
	light.position = Vector3(0.0, -0.7, 0.0)
	_bulb_arm.add_child(light)

func _build_sweep_lamp() -> void:
	var rail := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.02
	rm.bottom_radius = 0.02
	rm.height = 2.9
	rail.mesh = rm
	rail.rotation.z = PI * 0.5
	rail.position = Vector3(0.0, 3.0, 0.85)
	rail.material_override = _steel_mat(Color(0.3, 0.3, 0.33))
	add_child(rail)
	_lamp_house = MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.05
	hm.bottom_radius = 0.09
	hm.height = 0.18
	_lamp_house.mesh = hm
	_lamp_house.position = Vector3(0.0, 2.9, 0.85)
	_lamp_house.rotation.x = deg_to_rad(-40.0)
	_lamp_house.material_override = _glow_mat(LAMP_COLORS[0], 1.4)
	add_child(_lamp_house)
	_lamp = SpotLight3D.new()
	_lamp.light_color = LAMP_COLORS[0]
	_lamp.light_energy = 2.6
	_lamp.spot_range = 4.0
	_lamp.spot_angle = 26.0
	_lamp.position = Vector3(0.0, 2.9, 0.85)
	_lamp.rotation.x = deg_to_rad(-118.0)
	add_child(_lamp)

func _build_halo() -> void:
	# the room, folded in: the organ stands in its own disc of fog-light
	var halo := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 2.1
	hm.bottom_radius = 2.1
	hm.height = 0.02
	halo.mesh = hm
	halo.position = Vector3(0.0, 0.012, 0.1)
	var m := _glow_mat(Color(0.5, 0.45, 0.7), 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = 0.35
	halo.material_override = m
	add_child(halo)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "OrganPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-1.85, 0.24, 1.0)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("CHROMATIC ORGAN",
			"Twelve rungs, one instrument: the bulb, the three great pipes and their\nbasin, hue-ordered ranks in four dresses (matte, glow, glass, glitched),\na sweeping stage lamp re-dealing every seen-colour, the two roads up the\ntowers, complementary stops, grey keys on quarrelling felts, and a halo room.")
