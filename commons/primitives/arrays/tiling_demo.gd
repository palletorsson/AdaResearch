## TilingDemo — Standalone demo scene showcasing the tiling system.
## Shows Italian motifs as floor panels with different palettes and border compositions.
## Run this scene directly to test the tiling system.
extends Node3D

@export var panel_size: Vector2 = Vector2(2.5, 2.5)
@export var panel_spacing: float = 3.5

func _ready() -> void:
	_create_environment()
	_create_floor()
	_create_motif_gallery()
	_create_composed_floors()


# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
func _create_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.65)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Top-down light for floor viewing
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-70, 20, 0)
	light.light_color = Color(1.0, 0.97, 0.92)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, -120, 0)
	fill.light_color = Color(0.6, 0.7, 0.9)
	fill.light_energy = 0.3
	fill.shadow_enabled = false
	add_child(fill)

	# Camera — overhead angled view
	var cam := Camera3D.new()
	cam.position = Vector3(10, 12, 14)
	cam.rotation_degrees = Vector3(-45, 0, 0)
	cam.fov = 50
	add_child(cam)


# ---------------------------------------------------------------------------
# Base floor
# ---------------------------------------------------------------------------
func _create_floor() -> void:
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 30)
	floor_mesh.mesh = plane

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.14, 0.13)
	mat.roughness = 0.95
	floor_mesh.material_override = mat
	floor_mesh.position.y = -0.01
	add_child(floor_mesh)


# ---------------------------------------------------------------------------
# Row 1: Individual Motifs — one TilingSystem per motif
# ---------------------------------------------------------------------------
func _create_motif_gallery() -> void:
	# Motifs from the Italy study pack
	var motifs := [
		{"name": "Checkerboard", "motif": "checkerboard", "period": "roman_republican"},
		{"name": "Meander Key", "motif": "meander_key", "period": "roman_republican"},
		{"name": "Diamond Lozenge", "motif": "diamond_lozenge", "period": "roman_imperial"},
		{"name": "Octagon & Square", "motif": "octagon_square", "period": "roman_imperial"},
		{"name": "Perspective Cubes", "motif": "perspective_cubes", "period": "cosmatesque_period"},
		{"name": "Star Pattern", "motif": "star_pattern", "period": "cosmatesque_period"},
		{"name": "Floral Cross", "motif": "floral_cross", "period": "renaissance"},
		{"name": "Vine Scroll", "motif": "vine_scroll", "period": "baroque"},
	]

	# Section label
	var label := Label3D.new()
	label.text = "ITALIAN TILING MOTIFS"
	label.font_size = 64
	label.pixel_size = 0.003
	label.position = Vector3(0, 0.05, -1.5)
	label.rotation_degrees.x = -90
	label.modulate = Color(0.7, 0.7, 0.8)
	add_child(label)

	for i in range(motifs.size()):
		var spec: Dictionary = motifs[i]
		var col: int = i % 4
		var row: int = i / 4
		var x: float = col * panel_spacing
		var z: float = row * panel_spacing + 1.0

		_spawn_motif_panel(spec, Vector3(x, 0, z))


func _spawn_motif_panel(spec: Dictionary, pos: Vector3) -> void:
	var tiling := TilingSystem.new()
	tiling.name = "Tiling_%s" % spec["motif"]
	tiling.tile_size = 6
	tiling.field_size = Vector2i(3, 3)
	tiling.has_border = false
	tiling.has_corners = false
	tiling.has_medallion = false
	tiling.cell_size = 0.04
	tiling.position = pos
	add_child(tiling)

	# Load pack, set period, load motif — deferred so _ready() runs first
	tiling.call_deferred("_demo_setup", spec["motif"], spec.get("period", ""))

	# Label
	var label := Label3D.new()
	label.text = spec["name"]
	label.font_size = 32
	label.pixel_size = 0.002
	label.position = pos + Vector3(panel_size.x / 2.0, 0.05, panel_size.y + 0.3)
	label.rotation_degrees.x = -90
	label.modulate = Color(0.7, 0.7, 0.8)
	add_child(label)


# ---------------------------------------------------------------------------
# Row 2: Composed Floors — field + border + corners
# ---------------------------------------------------------------------------
func _create_composed_floors() -> void:
	var compositions := [
		{
			"name": "Casa del Fauno Floor",
			"site": "casa_del_fauno",
			"field_motif": "checkerboard",
			"border_motif": "meander_key",
		},
		{
			"name": "Santa Chiara Majolica",
			"site": "santa_chiara",
			"field_motif": "floral_cross",
			"border_motif": "vine_scroll",
		},
		{
			"name": "Cosmatesque Pavement",
			"site": "museo_archeologico",
			"field_motif": "perspective_cubes",
			"border_motif": "guilloche",
		},
	]

	# Section label
	var label := Label3D.new()
	label.text = "COMPOSED FLOORS"
	label.font_size = 64
	label.pixel_size = 0.003
	label.position = Vector3(0, 0.05, 9.0)
	label.rotation_degrees.x = -90
	label.modulate = Color(0.7, 0.7, 0.8)
	add_child(label)

	for i in range(compositions.size()):
		var spec: Dictionary = compositions[i]
		var x: float = i * (panel_spacing + 2.0)
		var z: float = 10.5

		_spawn_composed_floor(spec, Vector3(x, 0, z))


func _spawn_composed_floor(spec: Dictionary, pos: Vector3) -> void:
	var tiling := TilingSystem.new()
	tiling.name = "Composed_%s" % spec.get("name", "floor").replace(" ", "_")
	tiling.tile_size = 6
	tiling.field_size = Vector2i(3, 3)
	tiling.border_width = 4
	tiling.has_border = true
	tiling.has_corners = true
	tiling.has_medallion = false
	tiling.cell_size = 0.04
	tiling.position = pos
	add_child(tiling)

	# Deferred setup
	tiling.call_deferred("_demo_composed_setup",
		spec.get("site", ""),
		spec.get("field_motif", "checkerboard"),
		spec.get("border_motif", "meander_key"))

	# Label
	var label := Label3D.new()
	label.text = spec.get("name", "Floor")
	label.font_size = 32
	label.pixel_size = 0.002
	label.position = pos + Vector3(panel_size.x / 2.0, 0.05, panel_size.y + 1.5)
	label.rotation_degrees.x = -90
	label.modulate = Color(0.7, 0.7, 0.8)
	add_child(label)
