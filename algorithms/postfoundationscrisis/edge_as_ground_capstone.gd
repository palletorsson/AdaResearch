# Edge as Ground Capstone — the spine's literal last artifact
#
# A raised central platform. Around it: seven stations arranged in a ring, each station
# a small pedestal with a glowing emblem recalling one prior map of the postfoundation
# sequence:
#   1. bias_visualizer        → the limit
#   2. ethical_design         → ethics is shape
#   3. paraconsistent_engine  → hold contradiction
#   4. situated_compute       → knowledge has a body
#   5. collective_knowledge   → the commons
#   6. rhizome                → no hierarchy
#   7. molecular_design       → embodied formalism
#
# At the center: a slowly rotating thick disc of glass with the spine's final sentence
# inscribed: "The edge is the ground."
#
# The whole composition is the curriculum's argument made architectural. The player has
# walked everything. Now they stand at the spine's terminus and the rim recalls their
# journey. The capstone IS the closing of the thesis arc.
#
# @identity: Final artifact in the spine.
# @qfep_term: All — the formula's argument landed as architecture.

extends Node3D
class_name EdgeAsGroundCapstone

@export var platform_color: Color = Color(0.18, 0.2, 0.26, 1.0)
@export var station_color: Color = Color(0.95, 0.85, 0.55, 1.0)
@export var center_color: Color = Color(0.7, 0.95, 0.95, 1.0)
@export var ring_radius: float = 1.6
@export var platform_radius: float = 0.7
@export var rotation_speed: float = 0.2

# Each station: emblem-color, glyph (Label3D text), title
var _stations := [
	{"color": Color(1.0, 0.45, 0.4, 1.0), "title": "limit",          "emblem": "≠"},
	{"color": Color(0.85, 0.7, 0.4, 1.0),  "title": "ethics",         "emblem": "▢"},
	{"color": Color(0.95, 0.85, 0.3, 1.0), "title": "contradiction",  "emblem": "⊥"},
	{"color": Color(0.6, 0.95, 0.65, 1.0), "title": "situated",       "emblem": "⊕"},
	{"color": Color(0.7, 0.95, 0.85, 1.0), "title": "commons",        "emblem": "∞"},
	{"color": Color(0.55, 0.7, 0.95, 1.0), "title": "rhizome",        "emblem": "⌘"},
	{"color": Color(0.85, 0.55, 0.95, 1.0), "title": "molecular",      "emblem": "Φ"},
]
var _center_disc: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_platform()
	_build_stations()
	_build_center_disc()
	_build_central_inscription()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("ring_radius"):
		ring_radius = float(config_data["ring_radius"])


func _process(delta: float) -> void:
	_t += delta * rotation_speed
	if is_instance_valid(_center_disc):
		_center_disc.rotation.y = _t * 0.4


func _build_platform() -> void:
	var platform := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = platform_radius
	cyl.bottom_radius = platform_radius + 0.1
	cyl.height = 0.4
	platform.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = platform_color
	mat.metallic = 0.5
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = platform_color
	mat.emission_energy_multiplier = 0.4
	platform.material_override = mat
	platform.position.y = 0.2
	add_child(platform)


func _build_stations() -> void:
	for i in _stations.size():
		var station_data: Dictionary = _stations[i]
		var a: float = TAU * float(i) / float(_stations.size())
		var pos := Vector3(cos(a) * ring_radius, 0, sin(a) * ring_radius)
		# Pedestal.
		var pedestal := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.3, 0.7, 0.3)
		pedestal.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = platform_color
		mat.metallic = 0.4
		mat.roughness = 0.5
		pedestal.material_override = mat
		pedestal.position = pos + Vector3(0, 0.35, 0)
		add_child(pedestal)
		# Emblem (glowing sphere on top).
		var emblem_glow := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.12
		s.height = 0.24
		emblem_glow.mesh = s
		var emat := StandardMaterial3D.new()
		emat.albedo_color = station_data["color"]
		emat.emission_enabled = true
		emat.emission = station_data["color"]
		emat.emission_energy_multiplier = 2.0
		emblem_glow.material_override = emat
		emblem_glow.position = pos + Vector3(0, 0.85, 0)
		add_child(emblem_glow)
		# Glyph label on emblem.
		var glyph := Label3D.new()
		glyph.text = station_data["emblem"]
		glyph.font_size = 36
		glyph.outline_size = 6
		glyph.modulate = Color(0.1, 0.1, 0.13, 1.0)
		glyph.position = pos + Vector3(0, 0.85, 0.13)
		glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(glyph)
		# Title below.
		var title := Label3D.new()
		title.text = station_data["title"]
		title.font_size = 20
		title.outline_size = 4
		title.modulate = station_data["color"]
		title.position = pos + Vector3(0, 1.1, 0)
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(title)


func _build_center_disc() -> void:
	_center_disc = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = platform_radius * 0.85
	cyl.bottom_radius = platform_radius * 0.85
	cyl.height = 0.05
	_center_disc.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = center_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.4
	mat.metallic = 0.7
	mat.roughness = 0.1
	mat.emission_enabled = true
	mat.emission = center_color
	mat.emission_energy_multiplier = 0.8
	_center_disc.material_override = mat
	_center_disc.position.y = 0.45
	add_child(_center_disc)


func _build_central_inscription() -> void:
	var inscription := Label3D.new()
	inscription.text = "The edge is the ground."
	inscription.font_size = 38
	inscription.outline_size = 8
	inscription.modulate = center_color
	inscription.position = Vector3(0, 0.65, 0)
	inscription.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(inscription)
	# Subtitle: the spine's terminus.
	var sub := Label3D.new()
	sub.text = "F − λE(S) + φΔE(S,t)"
	sub.font_size = 20
	sub.outline_size = 5
	sub.modulate = Color(0.8, 0.85, 0.95, 1.0)
	sub.position = Vector3(0, 0.5, 0)
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sub)
