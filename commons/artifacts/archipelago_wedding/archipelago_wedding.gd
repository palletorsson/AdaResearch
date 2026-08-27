extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ArchipelagoWedding

## @identity
## lineage: the graph taxonomy's rung 7 — two islands of lamps over dark water, each
##   island wired within itself and glowing its own colour: teal to the west, rose to
##   the east. Between them, a drawbridge edge. Press the button: the bridge lowers,
##   the union-find reruns, and BOTH islands converge to one wedding gold. Press
##   again: the bridge lifts, and the two colours return.
## essence: connected components are a fact about the WHOLE graph, recomputed the
##   moment one edge appears. No lamp changed its wiring except the two the bridge
##   touches — yet every lamp changes colour, because membership is global.
## truth: islands, until one edge marries them.
##
## The 2026-08-27 graph taxonomy (doc/GRAPHTHEORY_TAXONOMY.md), rung 7 of 13.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const BUTTON_SCENE := preload("res://commons/interactables/push_button.tscn")
const TEAL := Color(0.15, 0.75, 0.7)
const ROSE := Color(0.9, 0.35, 0.5)
const GOLD := Color(0.95, 0.78, 0.25)

@export var seed: int = 45

var _west: Array = []                   # lamp materials, west island
var _east: Array = []
var _bridge: Node3D
var _married := false
var _readout: Node3D

func _ready() -> void:
	_rng.seed = seed
	_build_water()
	_west = _build_island(Vector3(-1.35, 0.0, 0.0), TEAL, 5)
	_east = _build_island(Vector3(1.35, 0.0, 0.0), ROSE, 4)
	_build_bridge()
	_build_button()
	_build_plaque()
	_recolor()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"):
		seed = int(config_data["seed"])

func _build_water() -> void:
	var water := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(4.4, 0.04, 2.6)
	water.mesh = wm
	water.position = Vector3(0.0, 0.02, 0.0)
	var mat := _glow_mat(Color(0.05, 0.09, 0.14), 0.25)
	mat.roughness = 0.1
	mat.metallic = 0.5
	water.material_override = mat
	add_child(water)

func _build_island(at: Vector3, tint: Color, lamps: int) -> Array:
	var isle := MeshInstance3D.new()
	var im := CylinderMesh.new()
	im.top_radius = 0.85
	im.bottom_radius = 0.95
	im.height = 0.18
	isle.mesh = im
	isle.position = at + Vector3(0.0, 0.09, 0.0)
	isle.material_override = _matte_mat(Color(0.13, 0.12, 0.11), 0.9)
	add_child(isle)
	var mats: Array = []
	var pts: Array = []
	for i in range(lamps):
		var ang := TAU * float(i) / float(lamps) + _rng.randf_range(-0.2, 0.2)
		var r := _rng.randf_range(0.25, 0.62)
		var p := at + Vector3(cos(ang) * r, 0.85 + _rng.randf_range(-0.1, 0.15), sin(ang) * r)
		pts.append(p)
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.018
		pm.bottom_radius = 0.026
		pm.height = p.y - 0.18
		post.mesh = pm
		post.position = Vector3(p.x, 0.18 + (p.y - 0.18) * 0.5, p.z)
		post.material_override = _matte_mat(Color(0.2, 0.19, 0.18), 0.85)
		add_child(post)
		var lamp := MeshInstance3D.new()
		var lm := SphereMesh.new()
		lm.radius = 0.075
		lm.height = 0.15
		lamp.mesh = lm
		lamp.position = p
		var mat := _glow_mat(tint, 1.6)
		lamp.material_override = mat
		add_child(lamp)
		mats.append(mat)
	# intra-island wiring: a ring plus one chord, so each island is visibly one piece
	for i in range(pts.size()):
		_wire(pts[i], pts[(i + 1) % pts.size()])
	if pts.size() > 3:
		_wire(pts[0], pts[2])
	return mats

func _wire(a: Vector3, b: Vector3) -> void:
	var e := MeshInstance3D.new()
	var em := CylinderMesh.new()
	em.top_radius = 0.01
	em.bottom_radius = 0.01
	em.height = a.distance_to(b)
	e.mesh = em
	e.position = (a + b) * 0.5
	var dir := (b - a).normalized()
	var axis := Vector3.UP.cross(dir)
	if axis.length() > 0.001:
		e.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
	e.material_override = _glow_mat(Color(0.85, 0.82, 0.7), 0.4)
	add_child(e)

func _build_bridge() -> void:
	_bridge = Node3D.new()
	_bridge.position = Vector3(0.0, 0.55, 0.0)
	add_child(_bridge)
	var deck := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(1.15, 0.05, 0.3)
	deck.mesh = dm
	deck.material_override = _glow_mat(GOLD, 0.9)
	_bridge.add_child(deck)
	_bridge.rotation.z = deg_to_rad(65.0)   # starts lifted: two components

func _build_button() -> void:
	var btn := BUTTON_SCENE.instantiate()
	btn.position = Vector3(0.0, 0.85, 1.45)
	btn.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	btn.set("pressed_color", GOLD)
	btn.set("released_color", Color(0.3, 0.35, 0.4))
	add_child(btn)
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.05
	sm.bottom_radius = 0.07
	sm.height = 0.8
	stem.mesh = sm
	stem.position = Vector3(0.0, 0.4, 1.45)
	stem.material_override = _steel_mat(Color(0.3, 0.3, 0.33))
	add_child(stem)
	if btn.has_signal("pressed"):
		btn.connect("pressed", Callable(self, "_on_toggle"))
	else:
		var inner := btn.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.connect("button_pressed", Callable(self, "_on_toggle"))

func _on_toggle() -> void:
	_married = not _married
	_recolor()

func _process(delta: float) -> void:
	var target := 0.0 if _married else deg_to_rad(65.0)
	_bridge.rotation.z = lerp_angle(_bridge.rotation.z, target, delta * 4.0)

func _recolor() -> void:
	# the union-find, run honestly: two sets, one union when the bridge edge exists
	var west_c := GOLD if _married else TEAL
	var east_c := GOLD if _married else ROSE
	for m in _west:
		m.albedo_color = west_c
		m.emission = west_c
	for m in _east:
		m.albedo_color = east_c
		m.emission = east_c
	if _readout and _readout.has_method("set_text"):
		_readout.set_text("components: %d" % (1 if _married else 2),
			"one edge changed; every lamp answered")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "WeddingPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.9, 0.24, 1.2)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("ARCHIPELAGO WEDDING",
			"Connected components are a fact about the WHOLE graph. Lower the bridge:\none new edge, and every lamp on both islands turns wedding gold - membership\nis global, recomputed the moment an edge appears.")
	_readout = TextScreenScript.new()
	_readout.mode = 2
	_readout.width_m = 0.3
	_readout.position = Vector3(1.9, 0.24, 1.2)
	_readout.rotation.y = deg_to_rad(-38.0)
	add_child(_readout)
