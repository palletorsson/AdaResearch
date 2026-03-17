## FacadePlanDemo — Standalone demo scene showcasing the facade plan importer.
##
## Shows two facades side-by-side:
##   1. A FacadePlanNode loaded from the test JSON file
##   2. A facade built via FacadePlanImporter.import_from_dict() with hardcoded data
##
## Run this scene directly to test the plan-based facade system.
extends Node3D


## Horizontal gap between the two demo facades.
@export var facade_gap: float = 4.0


func _ready() -> void:
	_create_environment()
	_create_floor()
	_create_json_facade()
	_create_dict_facade()


# ─── ENVIRONMENT ───────────────────────────────────────────────────────────

func _create_environment() -> void:
	# Sky + ambient
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.65, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.75, 0.85)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Sun
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-40, 25, 0)
	sun.light_color = Color(1.0, 0.95, 0.88)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)

	# Fill light
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-15, -130, 0)
	fill.light_color = Color(0.6, 0.65, 0.8)
	fill.light_energy = 0.35
	fill.shadow_enabled = false
	add_child(fill)

	# Camera — positioned to see both facades
	var cam := Camera3D.new()
	cam.name = "DemoCamera"
	cam.position = Vector3(14, 7, 22)
	cam.rotation_degrees = Vector3(-12, 0, 0)
	cam.fov = 50
	add_child(cam)


# ─── FLOOR ─────────────────────────────────────────────────────────────────

func _create_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	add_child(floor_body)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 30)
	floor_mesh.mesh = plane

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.35, 0.32, 0.28)
	floor_mat.roughness = 0.95
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)

	var col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(60, 0.1, 30)
	col.shape = col_shape
	col.position.y = -0.05
	floor_body.add_child(col)


# ─── FACADE 1: From JSON file via FacadePlanNode ──────────────────────────

func _create_json_facade() -> void:
	var plan_node := FacadePlanNode.new()
	plan_node.name = "Facade_FromJSON"
	plan_node.plan_path = "res://commons/mesh_grammar/study_packs/test_facade_plan.json"
	plan_node.position = Vector3(0, 0, 0)
	add_child(plan_node)

	# Title label
	var label := Label3D.new()
	label.text = "FROM JSON FILE"
	label.font_size = 48
	label.pixel_size = 0.003
	label.position = Vector3(6, -0.4, 0.5)
	label.modulate = Color(0.3, 0.25, 0.2)
	add_child(label)

	# Sub-label with filename
	var sub := Label3D.new()
	sub.text = "test_facade_plan.json  (5 bays × 5 stories, 12 m × 10 m)"
	sub.font_size = 28
	sub.pixel_size = 0.002
	sub.position = Vector3(6, -0.8, 0.5)
	sub.modulate = Color(0.45, 0.4, 0.35)
	add_child(sub)


# ─── FACADE 2: From Dictionary via import_from_dict() ─────────────────────

func _create_dict_facade() -> void:
	# A smaller, different facade built entirely in code
	var data := {
		"version": 1,
		"generator": "facade_plan_demo",
		"facade": {
			"bays": 3,
			"stories": 3,
			"symmetry": "bilateral",
			"total_width": 8.0,
			"total_height": 7.0,
			"primary_color": "#c8bca6",
			"secondary_color": "#9e9486",
		},
		"zones": [
			{ "row": 0, "name": "Cornice", "height_multiplier": 0.6, "color": "#FFA726" },
			{ "row": 1, "name": "Piano Nobile", "height_multiplier": 1.4, "color": "#8D6E63" },
			{ "row": 2, "name": "Base", "height_multiplier": 1.0, "color": "#78909C" },
		],
		"placements": [
			# Row 0 — cornice dentils
			{ "col": 0, "row": 0, "element_type": "dentil", "rotation": 0 },
			{ "col": 1, "row": 0, "element_type": "triangular_pediment", "rotation": 0 },
			{ "col": 2, "row": 0, "element_type": "dentil", "rotation": 0 },
			# Row 1 — piano nobile with columns and arched windows
			{ "col": 0, "row": 1, "element_type": "col_corinthian", "rotation": 0 },
			{ "col": 1, "row": 1, "element_type": "arched_window", "rotation": 0 },
			{ "col": 2, "row": 1, "element_type": "col_corinthian", "rotation": 0 },
			# Row 2 — base with door flanked by rustication
			{ "col": 0, "row": 2, "element_type": "rusticated_block", "rotation": 0 },
			{ "col": 1, "row": 2, "element_type": "door", "rotation": 0 },
			{ "col": 2, "row": 2, "element_type": "rusticated_block", "rotation": 0 },
		],
		"zone_colors": {
			"Cornice": "#D4C8B8",
			"Piano Nobile": "#C8BCA6",
			"Base": "#A89E8E",
		},
	}

	# Build via the static importer
	var x_offset := 12.0 + facade_gap
	var facade_node := FacadePlanImporter.import_from_dict(data)
	facade_node.position = Vector3(x_offset, 0, 0)
	add_child(facade_node)

	# Title label
	var label := Label3D.new()
	label.text = "FROM DICTIONARY"
	label.font_size = 48
	label.pixel_size = 0.003
	label.position = Vector3(x_offset + 4, -0.4, 0.5)
	label.modulate = Color(0.3, 0.25, 0.2)
	add_child(label)

	# Sub-label
	var sub := Label3D.new()
	sub.text = "Hardcoded config  (3 bays × 3 stories, 8 m × 7 m)"
	sub.font_size = 28
	sub.pixel_size = 0.002
	sub.position = Vector3(x_offset + 4, -0.8, 0.5)
	sub.modulate = Color(0.45, 0.4, 0.35)
	add_child(sub)
