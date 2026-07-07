extends Node3D
class_name QFEPPhaseApparatus

# @identity
# essence: the QFEP phase landscape arranged as a walkable circle. Seven
#   stations, seven phases, each named by ONE prop whose state IS the phase.
#   F_order = a frozen crystal in a specimen jar (cold-blue glow). Oscillation
#   = a pendulum frozen mid-swing (green arc dots). E_entropy = a chemistry
#   flask reacting (sickly emerald with bunsen heat). Lambda_edge =
#   a vacuum chamber at over-pressure (red alarm needle). Integration =
#   scales finding equilibrium (violet beam). Relation = a kaleidoscope
#   facing the player (yellow rosette). Synthesis = an autoclave running
#   (white). Walk the circle, walk the phase diagram.
# desire: every Ada Research sequence eventually arrives at QFEP. The phase
#   diagram needs a CHAMBER, not a chart — phases are felt as much as
#   reasoned. The walk gives the felt sense; the props give the names.
# critical_parameter: phase_offset_degrees — the seven stations are
#   distributed around a circle; phase_offset_degrees rotates which one the
#   player encounters first. Default = 0° puts F_order at the entrance.
# triggers: _ready() instantiates 7 props, sets phase-specific DNA, places
#   each at its angular station around the circle.
# emerges: the room is a phase diagram. Walking from F_order to synthesis IS
#   the trajectory through QFEP. The eye reads the phase by colour; the body
#   reads it by which station it stands at.
# needs: specimen_jar (F_order); pendulum (oscillation); chemistry_flask +
#   bunsen_burner (E_entropy); vacuum_chamber (lambda_edge); scales
#   (integration); kaleidoscope (relation); autoclave (synthesis).
# relationships: sibling chamber to turing_apparatus (Turing Machine Lab) —
#   same composer pattern, different curriculum. Where Turing arranged
#   props as a Turing machine model, the QFEP chamber arranges them as
#   a phase landscape.
# truth: phase is not a number, it is a place you stand. The QFEP chamber
#   makes the phases visitable.

## Seven phase stations arranged in a circle.
## Origin at the center of the floor; player enters from +Z and faces -Z.

# Each phase is (angle_degrees clockwise from +Z, color, prop)
# Angle 0° = +Z (player's back, entrance side, where F_order sits)
# We arrange the 7 phases at angles 0, 51.4, 102.9, 154.3, 205.7, 257.1, 308.6
# around a circle, walking clockwise looking from above.

const SCENE_SPECIMEN_JAR: PackedScene = preload("res://commons/artifacts/specimen_jar/specimen_jar.tscn")
const SCENE_PENDULUM: PackedScene = preload("res://commons/artifacts/pendulum/pendulum.tscn")
const SCENE_CHEMISTRY_FLASK: PackedScene = preload("res://commons/artifacts/chemistry_flask/chemistry_flask.tscn")
const SCENE_BUNSEN: PackedScene = preload("res://commons/artifacts/bunsen_burner/bunsen_burner.tscn")
const SCENE_VACUUM_CHAMBER: PackedScene = preload("res://commons/artifacts/vacuum_chamber/vacuum_chamber.tscn")
const SCENE_SCALES: PackedScene = preload("res://commons/artifacts/scales/scales.tscn")
const SCENE_KALEIDOSCOPE: PackedScene = preload("res://commons/artifacts/kaleidoscope/kaleidoscope.tscn")
const SCENE_AUTOCLAVE: PackedScene = preload("res://commons/artifacts/autoclave/autoclave.tscn")
const SCENE_LARGE_TABLE: PackedScene = preload("res://commons/artifacts/large_table/large_table.tscn")

@export_group("Apparatus")
@export var circle_radius: float = 2.8
@export var phase_offset_degrees: float = 0.0
## Whether each station has a small accent-coloured plinth (table) under it.
@export var plinth_under_stations: bool = true

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build_apparatus()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for child in get_children():
			child.queue_free()
		_built = false
		_build_apparatus()


func _read_metadata_overrides() -> void:
	if has_meta("config_circle_radius"):
		circle_radius = float(str(get_meta("config_circle_radius")))
	if has_meta("config_phase_offset_degrees"):
		phase_offset_degrees = float(str(get_meta("config_phase_offset_degrees")))


func _build_apparatus() -> void:
	# Phase color palette (matches lab_room_gallery manifest)
	var phases: Array = [
		{
			"name": "F_order",
			"color": Color(0.227, 0.482, 1.0),       # blue
			"builder": Callable(self, "_build_f_order_station"),
		},
		{
			"name": "oscillation",
			"color": Color(0.490, 1.0, 0.659),       # green
			"builder": Callable(self, "_build_oscillation_station"),
		},
		{
			"name": "E_entropy",
			"color": Color(0.957, 0.635, 0.380),     # orange
			"builder": Callable(self, "_build_e_entropy_station"),
		},
		{
			"name": "lambda_edge",
			"color": Color(0.902, 0.224, 0.275),     # red
			"builder": Callable(self, "_build_lambda_edge_station"),
		},
		{
			"name": "integration",
			"color": Color(0.608, 0.365, 0.890),     # violet
			"builder": Callable(self, "_build_integration_station"),
		},
		{
			"name": "relation",
			"color": Color(0.984, 0.890, 0.541),     # yellow
			"builder": Callable(self, "_build_relation_station"),
		},
		{
			"name": "synthesis",
			"color": Color(1.0, 1.0, 1.0),           # white
			"builder": Callable(self, "_build_synthesis_station"),
		},
	]

	var n: int = phases.size()
	for i in range(n):
		var phase: Dictionary = phases[i]
		var angle_deg: float = phase_offset_degrees + (360.0 * float(i) / float(n))
		var angle_rad: float = deg_to_rad(angle_deg)
		# Player enters from +Z facing -Z; place F_order at angle 0 = +Z
		# (which is BEHIND the player), then walk clockwise.
		var pos: Vector3 = Vector3(
			sin(angle_rad) * circle_radius,
			0.0,
			cos(angle_rad) * circle_radius,
		)
		var station_root := Node3D.new()
		station_root.name = "Station_%d_%s" % [i + 1, phase["name"]]
		station_root.position = pos
		# Rotate the station so its "front" faces the circle center
		var face_angle: float = atan2(-pos.x, -pos.z)
		station_root.rotation = Vector3(0.0, face_angle, 0.0)
		add_child(station_root)

		# Plinth (small table) underneath the station's prop
		if plinth_under_stations:
			var table: Node3D = SCENE_LARGE_TABLE.instantiate()
			table.set("length", 0.65)
			table.set("depth", 0.55)
			table.set("height", 0.75)
			table.set("leg_style", "post")
			table.set("top_color", Color(0.92, 0.92, 0.94))
			table.set("leg_color", Color(0.18, 0.18, 0.22))
			table.set("accent_color", phase["color"])
			table.set("edge_strip", true)
			station_root.add_child(table)

		# The phase-specific prop
		(phase["builder"] as Callable).call(station_root, phase["color"])

	_built = true


# ── Per-phase station builders ────────────────────────────────────────

func _build_f_order_station(parent: Node3D, color: Color) -> void:
	var jar: Node3D = SCENE_SPECIMEN_JAR.instantiate()
	jar.set("content_shape", "crystal")
	jar.set("content_color", color)
	jar.set("content_glow", 1.4)
	jar.set("jar_height", 0.45)
	jar.set("plinth_height", 0.10)
	jar.set("plinth_width", 0.30)
	jar.set("label_text", "F_order")
	jar.set("label_color", color)
	jar.position = Vector3(0.0, 0.78, 0.0)  # on top of table
	parent.add_child(jar)


func _build_oscillation_station(parent: Node3D, color: Color) -> void:
	var pendulum: Node3D = SCENE_PENDULUM.instantiate()
	pendulum.set("stand_height", 0.50)
	pendulum.set("string_length", 0.35)
	pendulum.set("swing_angle_degrees", 25.0)
	pendulum.set("bob_color", color)
	pendulum.set("bob_emission", 0.6)
	pendulum.set("arc_visible", true)
	pendulum.set("arc_dot_count", 9)
	pendulum.set("accent_color", color)
	pendulum.position = Vector3(0.0, 0.78, 0.0)
	parent.add_child(pendulum)


func _build_e_entropy_station(parent: Node3D, color: Color) -> void:
	# Flask + bunsen pair — the canonical chaos: reacting glass over flame
	var flask: Node3D = SCENE_CHEMISTRY_FLASK.instantiate()
	flask.set("flask_shape", "round_bottom")
	flask.set("flask_height", 0.30)
	flask.set("flask_max_radius", 0.10)
	flask.set("content_color", color)
	flask.set("content_height_fraction", 0.50)
	flask.set("has_stopper", false)
	flask.set("label_text", "E_ent")
	flask.position = Vector3(0.12, 0.78, 0.0)
	parent.add_child(flask)

	var burner: Node3D = SCENE_BUNSEN.instantiate()
	burner.set("flame_color", color)
	burner.set("flame_height", 0.14)
	burner.set("flame_visible", true)
	burner.set("valve_position", "medium")
	burner.set("accent_color", color)
	burner.position = Vector3(-0.15, 0.78, 0.0)
	parent.add_child(burner)


func _build_lambda_edge_station(parent: Node3D, color: Color) -> void:
	var chamber: Node3D = SCENE_VACUUM_CHAMBER.instantiate()
	chamber.set("jar_height", 0.45)
	chamber.set("jar_radius", 0.15)
	chamber.set("platform_radius", 0.22)
	chamber.set("platform_height", 0.08)
	chamber.set("pressure_status", "over")
	chamber.set("interior_color", color)
	chamber.set("interior_glow", 1.4)
	chamber.set("specimen_visible", true)
	chamber.set("specimen_color", color)
	chamber.set("accent_color", color)
	chamber.position = Vector3(0.0, 0.78, 0.0)
	parent.add_child(chamber)


func _build_integration_station(parent: Node3D, color: Color) -> void:
	var scales: Node3D = SCENE_SCALES.instantiate()
	scales.set("beam_length", 0.42)
	scales.set("base_radius", 0.12)
	scales.set("pan_radius", 0.075)
	scales.set("left_load", 2.0)
	scales.set("right_load", 2.0)
	scales.set("tilt_from_loads", true)
	scales.set("base_color", color)
	scales.set("beam_color", color)
	scales.set("pan_color", color)
	scales.set("accent_color", color)
	scales.position = Vector3(0.0, 0.78, 0.0)
	parent.add_child(scales)


func _build_relation_station(parent: Node3D, color: Color) -> void:
	var kal: Node3D = SCENE_KALEIDOSCOPE.instantiate()
	kal.set("mirror_count", 6)
	kal.set("pattern_segments", 12)
	kal.set("tube_length", 0.35)
	kal.set("pattern_color_a", color)
	kal.set("pattern_color_b", Color(color.r * 0.7, color.g * 0.7, color.b * 1.2))
	kal.set("pattern_color_c", Color(1.0, color.g * 0.5, color.b * 0.3))
	kal.set("accent_color", color)
	kal.position = Vector3(0.0, 0.78, 0.0)
	# Rotate so the pattern face is visible toward the circle center
	kal.rotation = Vector3(0.0, deg_to_rad(-90.0), 0.0)
	parent.add_child(kal)


func _build_synthesis_station(parent: Node3D, color: Color) -> void:
	var clave: Node3D = SCENE_AUTOCLAVE.instantiate()
	clave.set("body_width", 0.45)
	clave.set("body_height", 0.65)
	clave.set("body_depth", 0.50)
	clave.set("door_radius", 0.16)
	clave.set("door_open", false)
	clave.set("status_indicator", true)
	clave.set("status_color", Color(0.30, 0.85, 0.40))
	clave.set("accent_color", color)
	clave.set("signage_text", "SYNTH")
	clave.position = Vector3(0.0, 0.78, 0.0)
	parent.add_child(clave)
