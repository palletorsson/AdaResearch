extends Node3D
class_name FoundationsCrisisApparatus

# @identity
# essence: five stations laid out in a hall, each naming one of the five
#   known limits of mathematics. Halting (emergency_button) — you cannot
#   in general decide whether a program halts. Cantor (microscope at 6
#   objectives) — you cannot enumerate the reals. Russell (vacuum_chamber
#   containing a smaller chamber) — you cannot have unrestricted
#   comprehension. Gödel (electrical_panel encoding statements as bits) —
#   you cannot have a complete consistent theory of arithmetic.
#   Hilbert (whiteboard + locked box) — you cannot have the formalist
#   program. Walking the hall meets each impossibility in turn.
# desire: the foundations crisis is the SHAPE OF Ada Research's middle
#   region. A chamber that makes the crisis walkable turns the abstract
#   undecidabilities into rooms you pass through.
# critical_parameter: station_count (5) and station_spacing — the hall's
#   length and rhythm. Longer hall = more weight per station.
# triggers: _ready() instantiates 5 prop groups, each at its station
#   position along the hall.
# emerges: the hall IS the crisis. Five stations, five known limits, in
#   the order Gödel learned them. The order is pedagogical: halting is
#   intuitive, Cantor next, Russell next, Gödel deepest, Hilbert's program
#   the closing summary.
# needs: emergency_button, microscope, vacuum_chamber, electrical_panel,
#   whiteboard, lock_box.
# relationships: sibling to turing_apparatus and qfep_phase_apparatus.
#   Same composer pattern, different curriculum.
# truth: every formal system has its outside. The hall makes the outside
#   visible.

## Five stations along a hall.
## Origin at the entrance; stations extend in -Z direction.
## Player enters from +Z facing -Z and walks down the hall.

const SCENE_EMERGENCY_BUTTON: PackedScene = preload("res://commons/artifacts/emergency_button/emergency_button.tscn")
const SCENE_MICROSCOPE: PackedScene = preload("res://commons/artifacts/microscope/microscope.tscn")
const SCENE_VACUUM_CHAMBER: PackedScene = preload("res://commons/artifacts/vacuum_chamber/vacuum_chamber.tscn")
const SCENE_ELECTRICAL_PANEL: PackedScene = preload("res://commons/artifacts/electrical_panel/electrical_panel.tscn")
const SCENE_WHITEBOARD: PackedScene = preload("res://commons/artifacts/whiteboard/whiteboard.tscn")
const SCENE_LOCK_BOX: PackedScene = preload("res://commons/artifacts/lock_box/lock_box.tscn")
const SCENE_LARGE_TABLE: PackedScene = preload("res://commons/artifacts/large_table/large_table.tscn")
const SCENE_SPECIMEN_JAR: PackedScene = preload("res://commons/artifacts/specimen_jar/specimen_jar.tscn")

@export var station_spacing: float = 2.4
@export var station_z_offset: float = -0.5  # start the first station offset from origin

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
	if has_meta("config_station_spacing"):
		station_spacing = float(String(get_meta("config_station_spacing")))


func _build_apparatus() -> void:
	# Five stations down the hall (-Z direction). Each station gets a
	# table, the limit-naming prop, and a whiteboard with the formal
	# statement. Stations alternate left/right to make the hall walkable.

	var stations: Array = [
		{
			"name": "halting",
			"title": "HALTING PROBLEM",
			"side": -1,  # -X (left)
			"limit_text": "no algorithm decides if M(w) halts",
			"builder": Callable(self, "_build_halting_station"),
		},
		{
			"name": "cantor",
			"title": "CANTOR'S DIAGONAL",
			"side": 1,   # +X (right)
			"limit_text": "|R| > |N| — the reals are uncountable",
			"builder": Callable(self, "_build_cantor_station"),
		},
		{
			"name": "russell",
			"title": "RUSSELL'S PARADOX",
			"side": -1,
			"limit_text": "{ x : x ∉ x } cannot be a set",
			"builder": Callable(self, "_build_russell_station"),
		},
		{
			"name": "godel",
			"title": "GÖDEL INCOMPLETENESS",
			"side": 1,
			"limit_text": "for every theory T, statements undecidable in T",
			"builder": Callable(self, "_build_godel_station"),
		},
		{
			"name": "hilbert",
			"title": "HILBERT'S PROGRAM",
			"side": -1,
			"limit_text": "the formalist agenda — what it tried to prove",
			"builder": Callable(self, "_build_hilbert_station"),
		},
	]

	for i in range(stations.size()):
		var spec: Dictionary = stations[i]
		var z_pos: float = station_z_offset - float(i) * station_spacing
		var x_pos: float = 1.8 * float(spec["side"])

		var station_root := Node3D.new()
		station_root.name = "Station_%d_%s" % [i + 1, spec["name"]]
		station_root.position = Vector3(x_pos, 0.0, z_pos)
		# Face the center of the hall (+X if side=-1, -X if side=+1)
		var face_angle: float = deg_to_rad(90.0) * float(spec["side"])
		station_root.rotation = Vector3(0.0, face_angle, 0.0)
		add_child(station_root)

		# Table under the prop
		var table: Node3D = SCENE_LARGE_TABLE.instantiate()
		table.set("length", 1.20)
		table.set("depth", 0.65)
		table.set("height", 0.85)
		table.set("leg_style", "panel")
		table.set("top_color", Color(0.88, 0.88, 0.90))
		table.set("leg_color", Color(0.18, 0.18, 0.22))
		table.set("accent_color", Color(0.902, 0.224, 0.275))  # lambda_edge red — the foundations are at the edge
		table.set("edge_strip", true)
		station_root.add_child(table)

		# The limit-naming prop, placed on top of the table
		(spec["builder"] as Callable).call(station_root, spec)

		# Whiteboard mounted on the wall behind the station, with the
		# formal statement of the limit.
		var board: Node3D = SCENE_WHITEBOARD.instantiate()
		board.set("board_width", 1.30)
		board.set("board_height", 0.85)
		board.set("text_lines", PackedStringArray([
			spec["title"],
			"",
			spec["limit_text"],
		]))
		board.set("text_size", 28)
		board.set("text_color", Color(0.10, 0.10, 0.12))
		board.position = Vector3(0.0, 1.80, -0.50)  # behind the table, above
		station_root.add_child(board)


# ── Per-station builders ──────────────────────────────────────────────

func _build_halting_station(parent: Node3D, _spec: Dictionary) -> void:
	var btn: Node3D = SCENE_EMERGENCY_BUTTON.instantiate()
	btn.set("mounting", "wall")
	btn.set("pressed", false)
	btn.set("label_text", "HALT?")
	btn.set("button_color", Color(0.95, 0.10, 0.10))
	btn.set("plate_color", Color(0.98, 0.85, 0.10))
	btn.set("plate_width", 0.32)
	btn.set("plate_height", 0.32)
	btn.set("button_radius", 0.10)
	btn.position = Vector3(0.0, 1.05, 0.0)  # on top of table
	parent.add_child(btn)


func _build_cantor_station(parent: Node3D, _spec: Dictionary) -> void:
	var scope: Node3D = SCENE_MICROSCOPE.instantiate()
	scope.set("body_height", 0.42)
	scope.set("eyepiece_count", 2)
	scope.set("objective_count", 6)  # 6 levels of zoom = countably many, never finishing
	scope.set("light_on", true)
	scope.set("accent_color", Color(0.902, 0.224, 0.275))
	scope.position = Vector3(0.0, 0.93, 0.0)
	parent.add_child(scope)


func _build_russell_station(parent: Node3D, _spec: Dictionary) -> void:
	# A vacuum chamber CONTAINING a specimen jar — the chamber that
	# contains itself. The specimen jar inside is labelled "{x : x ∉ x}".
	var chamber: Node3D = SCENE_VACUUM_CHAMBER.instantiate()
	chamber.set("jar_height", 0.55)
	chamber.set("jar_radius", 0.18)
	chamber.set("platform_radius", 0.26)
	chamber.set("platform_height", 0.08)
	chamber.set("pressure_status", "atmospheric")
	chamber.set("specimen_visible", false)  # we'll add our own specimen
	chamber.set("interior_glow", 0.5)
	chamber.set("interior_color", Color(0.902, 0.224, 0.275))
	chamber.set("accent_color", Color(0.902, 0.224, 0.275))
	chamber.position = Vector3(0.0, 0.93, 0.0)
	parent.add_child(chamber)

	# Smaller jar inside, labelled with the set
	var inner_jar: Node3D = SCENE_SPECIMEN_JAR.instantiate()
	inner_jar.set("jar_height", 0.18)
	inner_jar.set("jar_radius", 0.05)
	inner_jar.set("plinth_height", 0.04)
	inner_jar.set("plinth_width", 0.10)
	inner_jar.set("content_shape", "empty")
	inner_jar.set("content_glow", 0.0)
	inner_jar.set("label_text", "x∉x")
	inner_jar.set("label_color", Color(0.902, 0.224, 0.275))
	inner_jar.position = Vector3(0.0, 1.13, 0.0)  # inside the chamber
	parent.add_child(inner_jar)


func _build_godel_station(parent: Node3D, _spec: Dictionary) -> void:
	# An electrical panel — bits encoding statements about themselves.
	# Door open so the breaker grid (the encoded statement) is visible.
	var panel: Node3D = SCENE_ELECTRICAL_PANEL.instantiate()
	panel.set("panel_width", 0.55)
	panel.set("panel_height", 0.80)
	panel.set("door_open", true)
	panel.set("breaker_count", 14)
	panel.set("breakers_on_count", 7)  # half on = pseudo-random Gödel number
	panel.set("status_color", Color(0.30, 0.85, 0.40))
	panel.set("accent_color", Color(0.98, 0.78, 0.12))
	panel.set("signage_text", "GÖDEL NUMBER")
	panel.position = Vector3(0.0, 1.55, 0.0)
	parent.add_child(panel)


func _build_hilbert_station(parent: Node3D, _spec: Dictionary) -> void:
	# A locked box — the "secret of mathematics" that turned out to be
	# unattainable. Hilbert's program tried to commit math to a finitary
	# proof; the box is what we hoped was inside, sealed forever.
	var lock: Node3D = SCENE_LOCK_BOX.instantiate()
	lock.set("box_width", 0.32)
	lock.set("box_height", 0.22)
	lock.set("box_depth", 0.20)
	lock.set("lid_open_amount", 0.0)
	lock.set("combination_dial_count", 6)
	lock.set("dial_positions", PackedInt32Array([1, 9, 2, 0, 0, 0]))  # 1920 ish — the date Hilbert formulated the program
	lock.set("body_color", Color(0.18, 0.18, 0.22))
	lock.set("dial_color", Color(0.85, 0.65, 0.20))
	lock.set("accent_color", Color(0.902, 0.224, 0.275))
	lock.position = Vector3(0.0, 0.96, 0.0)
	parent.add_child(lock)
