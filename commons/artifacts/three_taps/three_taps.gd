extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ThreeTaps

## @identity
## lineage: the color taxonomy's rung 2 — a brass basin under three faucets labelled R,
##   G and B, each with its own slider. Open the taps and three beams of channel-light
##   pour into one pool, and the pool's water is exactly Color(r, g, b).
## essence: additive mixing as PLUMBING. The whole visible world is three floats in a
##   trench coat; here the floats are tap handles, the trench coat is a basin, and the
##   sum is something you can lean over and look into.
## truth: Color(r, g, b) — the basin sums what the taps admit. All three open is white;
##   all three shut is the basin at night.
##
## The 2026-08-27 color taxonomy (doc/COLOR_TAXONOMY.md), rung 2 of 12.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const SLIDER_SCENE := preload("res://commons/interactables/slider_horizontal.tscn")
const CHANNELS := [Color(1, 0.12, 0.1), Color(0.15, 1, 0.2), Color(0.2, 0.35, 1)]

@export var seed: int = 22
## Opening levels the artifact boots with — deliberately unequal, so the first glance
## already shows a MIX, not a textbook white.
@export var r0: float = 0.85
@export var g0: float = 0.35
@export var b0: float = 0.6

var _levels: Array = [0.85, 0.35, 0.6]
var _streams: Array = []               # emissive beam per channel
var _water_mat: StandardMaterial3D
var _readout: Node3D

func _ready() -> void:
	_rng.seed = seed
	_levels = [r0, g0, b0]
	_build_basin()
	_build_taps()
	_build_plaque()
	_apply_mix()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "r0", "g0", "b0"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- basin --------------------------------------------------------------------------

func _build_basin() -> void:
	var brass := _steel_mat(Color(0.55, 0.46, 0.28))
	var bowl := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.85
	bm.bottom_radius = 0.62
	bm.height = 0.5
	bowl.mesh = bm
	bowl.position = Vector3(0.0, 0.45, 0.0)
	bowl.material_override = brass
	add_child(bowl)
	var rim := MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = 0.8
	rm.outer_radius = 0.9
	rim.mesh = rm
	rim.position = Vector3(0.0, 0.7, 0.0)
	rim.material_override = brass
	add_child(rim)
	var water := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 0.78
	wm.bottom_radius = 0.78
	wm.height = 0.02
	water.mesh = wm
	water.position = Vector3(0.0, 0.62, 0.0)
	_water_mat = _glow_mat(Color(0.85, 0.35, 0.6), 1.5)
	_water_mat.roughness = 0.05
	_water_mat.metallic = 0.4
	water.material_override = _water_mat
	add_child(water)
	var pedestal := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.3
	pm.bottom_radius = 0.42
	pm.height = 0.2
	pedestal.mesh = pm
	pedestal.position = Vector3(0.0, 0.1, 0.0)
	pedestal.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
	add_child(pedestal)

# --- taps ---------------------------------------------------------------------------

func _build_taps() -> void:
	var brass := _steel_mat(Color(0.55, 0.46, 0.28))
	for i in range(3):
		var ang := -PI / 4.0 + PI / 4.0 * float(i)     # three spouts fanned over the bowl
		var base := Vector3(sin(ang) * 1.15, 0.0, -cos(ang) * 1.15)
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.035
		pm.bottom_radius = 0.05
		pm.height = 1.5
		post.mesh = pm
		post.position = base + Vector3(0.0, 0.75, 0.0)
		post.material_override = brass
		add_child(post)
		# the spout elbows out over the water
		var spout_dir := (Vector3(0.0, 0.0, 0.0) - Vector3(base.x, 0.0, base.z)).normalized()
		var spout_tip := base + spout_dir * 0.55 + Vector3(0.0, 1.5, 0.0)
		var arm := MeshInstance3D.new()
		var am := CylinderMesh.new()
		am.top_radius = 0.03
		am.bottom_radius = 0.03
		am.height = 0.58
		arm.mesh = am
		arm.position = (base + Vector3(0.0, 1.5, 0.0) + spout_tip) * 0.5
		arm.rotation.y = atan2(spout_dir.x, spout_dir.z)
		arm.rotation.x = PI * 0.5
		arm.material_override = brass
		add_child(arm)
		# the channel's stream: an emissive beam from spout to water, alpha = its level
		var stream := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.028
		sm.bottom_radius = 0.05
		sm.height = spout_tip.y - 0.63
		stream.mesh = sm
		stream.position = Vector3(spout_tip.x, (spout_tip.y + 0.63) * 0.5, spout_tip.z)
		var mat := _glow_mat(CHANNELS[i], 2.0)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		stream.material_override = mat
		add_child(stream)
		_streams.append(mat)
		# the slider that IS the float, mounted on the front skirt
		var slider := SLIDER_SCENE.instantiate()
		slider.position = Vector3(-0.55 + 0.55 * float(i), 0.34, 1.05)
		slider.rotation = Vector3(deg_to_rad(-30.0), 0.0, 0.0)
		add_child(slider)
		if slider.has_signal("slider_moved"):
			slider.connect("slider_moved", Callable(self, "_on_level").bind(i))
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.1
		tag.position = Vector3(-0.55 + 0.55 * float(i), 0.24, 1.32)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text(["R", "G", "B"][i], "")

func _on_level(value: float, i: int) -> void:
	_levels[i] = clampf(value, 0.0, 1.0)
	_apply_mix()

func _apply_mix() -> void:
	var mix := Color(_levels[0], _levels[1], _levels[2])
	_water_mat.albedo_color = mix
	_water_mat.emission = mix
	# an empty basin should go dark, not glow black-as-a-color
	_water_mat.emission_energy_multiplier = 0.2 + 2.0 * maxf(mix.r, maxf(mix.g, mix.b))
	for i in range(3):
		var m: StandardMaterial3D = _streams[i]
		m.albedo_color.a = 0.12 + 0.75 * _levels[i]
		m.emission_energy_multiplier = 0.3 + 2.4 * _levels[i]
	if _readout and _readout.has_method("set_text"):
		_readout.set_text("Color(%.2f, %.2f, %.2f)" % [_levels[0], _levels[1], _levels[2]],
			"the basin, as the engine spells it")

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "TapsPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.25, 0.24, 0.55)
	ts.rotation.y = deg_to_rad(40.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THREE TAPS",
			"Additive: the basin sums what the taps admit. All three open is white;\nall three shut is the basin at night. The whole visible world,\nthree floats in a trench coat.")
	_readout = TextScreenScript.new()
	_readout.mode = 2
	_readout.width_m = 0.34
	_readout.position = Vector3(1.25, 0.24, 0.55)
	_readout.rotation.y = deg_to_rad(-40.0)
	add_child(_readout)
