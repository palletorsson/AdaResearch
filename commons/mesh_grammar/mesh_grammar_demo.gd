## MeshGrammarDemo — Standalone demo scene that showcases all mesh grammar operations.
## Creates a gallery of procedural forms on a simple floor.
## Run this scene directly to test the mesh grammar system.
extends Node3D

const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

@export var spacing: float = 1.2
@export var object_height: float = 0.8

func _ready() -> void:
	_create_environment()
	_create_floor()
	_create_gallery()

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
func _create_environment() -> void:
	# Sky + ambient
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.35, 0.45)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.4

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Main light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_color = Color(1.0, 0.95, 0.9)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)

	# Fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -120, 0)
	fill.light_color = Color(0.6, 0.7, 0.9)
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	add_child(fill)

	# Camera
	var cam := Camera3D.new()
	cam.position = Vector3(0, 3.5, 6.0)
	cam.rotation_degrees = Vector3(-25, 0, 0)
	cam.fov = 50
	add_child(cam)

# ---------------------------------------------------------------------------
# Floor
# ---------------------------------------------------------------------------
func _create_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	add_child(floor_body)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(14, 10)
	floor_mesh.mesh = plane

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.12, 0.12, 0.16)
	floor_mat.metallic = 0.1
	floor_mat.roughness = 0.9
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)

	var col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(14, 0.1, 10)
	col.shape = col_shape
	col.position.y = -0.05
	floor_body.add_child(col)

# ---------------------------------------------------------------------------
# Gallery — one specimen per grammar recipe
# ---------------------------------------------------------------------------
func _create_gallery() -> void:
	var specimens: Array[Dictionary] = []

	# --- Row 1: Basic operations ---

	# 1. Plain icosahedron (seed reference)
	specimens.append({
		"name": "Seed Icosahedron",
		"seed": "icosahedron",
		"color": Color(0.5, 0.6, 0.7),
		"rules": [],
		"generations": 0
	})

	# 2. Extruded spire
	specimens.append({
		"name": "Extruded Spire",
		"seed": "icosahedron",
		"color": Color(0.9, 0.5, 0.2),
		"rules": [
			{"op": "extrude", "selector": "up", "params": {"distance": 0.3, "scale": 0.7}},
			{"op": "extrude", "selector": "tag:extruded_top", "params": {"distance": 0.25, "scale": 0.6}},
		],
		"generations": 1
	})

	# 3. Inset pattern
	specimens.append({
		"name": "Inset Pattern",
		"seed": "icosahedron",
		"color": Color(0.3, 0.8, 0.5),
		"rules": [
			{"op": "inset", "selector": "all", "params": {"amount": 0.35}},
		],
		"generations": 1
	})

	# 4. Subdivided sphere
	specimens.append({
		"name": "Subdivided",
		"seed": "icosahedron",
		"color": Color(0.4, 0.5, 0.9),
		"rules": [
			{"op": "split", "selector": "all", "params": {"pattern": "midpoint"}},
		],
		"generations": 1
	})

	# --- Row 2: Organic forms ---

	# 5. Nodule sphere (ceramic photo 1)
	specimens.append({
		"name": "Nodule Sphere",
		"seed": "sphere",
		"color": Color(0.6, 0.65, 0.8),
		"rules": [
			{"op": "bulge", "selector": "random:0.12", "params": {"height": 0.15, "ring_depth": 2, "smoothing": 0.5}},
		],
		"generations": 1
	})

	# 6. Coral fingers (ceramic photos 2-3)
	specimens.append({
		"name": "Coral Fingers",
		"seed": "sphere",
		"color": Color(0.55, 0.65, 0.85),
		"rules": [
			{"op": "tube_branch", "selector": "up_random", "params": {"length": 0.3, "curve_amount": 0.05, "segments": 5, "rings": 3}},
		],
		"generations": 1
	})

	# 7. Crumpled vessel (ceramic photo 4)
	specimens.append({
		"name": "Crumpled Form",
		"seed": "sphere",
		"color": Color(0.9, 0.85, 0.7),
		"rules": [
			{"op": "noise", "selector": "up", "params": {"amplitude": 0.15, "frequency": 3.0, "direction": "normal"}},
		],
		"generations": 1
	})

	# 8. Budding sphere with openings (ceramic photo 5)
	specimens.append({
		"name": "Budding Sphere",
		"seed": "sphere",
		"color": Color(0.85, 0.8, 0.75),
		"rules": [
			{"op": "extrude", "selector": "random:0.1", "params": {"distance": 0.2, "scale": 0.8}},
			{"op": "delete", "selector": "tag:extruded_top", "params": {}},
		],
		"generations": 1
	})

	# --- Row 3: Compound forms ---

	# 9. Multi-generation coral
	specimens.append({
		"name": "Branching Coral",
		"seed": "icosahedron",
		"color": Color(0.9, 0.4, 0.5),
		"rules": [
			{"op": "tube_branch", "selector": "up_random", "params": {"length": 0.2, "curve_amount": 0.08, "segments": 5, "rings": 3, "tip_tag": "branch_tip"}},
			{"op": "tube_branch", "selector": "tag:branch_tip", "params": {"length": 0.15, "curve_amount": 0.1, "segments": 4, "rings": 2, "tip_tag": "branch_tip"}},
		],
		"generations": 2
	})

	# 10. Inset + extrude (architectural)
	specimens.append({
		"name": "Inset Towers",
		"seed": "cube",
		"color": Color(0.8, 0.6, 0.3),
		"rules": [
			{"op": "inset", "selector": "up", "params": {"amount": 0.3}},
			{"op": "extrude", "selector": "tag:inset", "params": {"distance": 0.4, "scale": 0.7}},
		],
		"generations": 1
	})

	# 11. Split + bulge (organic detail)
	specimens.append({
		"name": "Detailed Bulge",
		"seed": "icosahedron",
		"color": Color(0.7, 0.5, 0.8),
		"rules": [
			{"op": "split", "selector": "all", "params": {"pattern": "midpoint"}},
			{"op": "bulge", "selector": "random:0.08", "params": {"height": 0.1, "ring_depth": 1, "smoothing": 0.6}},
		],
		"generations": 1
	})

	# 12. Full noise crumple
	specimens.append({
		"name": "Noise Sculpture",
		"seed": "sphere",
		"color": Color(0.3, 0.7, 0.6),
		"rules": [
			{"op": "noise", "selector": "all", "params": {"amplitude": 0.2, "frequency": 2.0, "direction": "radial", "noise_type": "cellular"}},
		],
		"generations": 1
	})

	# Layout specimens in a grid
	var cols: int = 4
	for i in range(specimens.size()):
		var spec := specimens[i]
		var col: int = i % cols
		var row: int = i / cols
		var x: float = (col - (cols - 1) * 0.5) * spacing
		var z: float = (row - 1.0) * spacing * 1.2

		var node := _build_specimen(spec)
		node.position = Vector3(x, object_height, z)
		add_child(node)

		# Label
		var label := Label3D.new()
		label.text = spec["name"]
		label.font_size = 32
		label.pixel_size = 0.002
		label.position = Vector3(x, 0.05, z + 0.45)
		label.rotation_degrees.x = -90
		label.modulate = Color(0.7, 0.7, 0.8)
		add_child(label)

# ---------------------------------------------------------------------------
# Build a single specimen from recipe
# ---------------------------------------------------------------------------
func _build_specimen(spec: Dictionary) -> MeshGrammarNode:
	var node := MeshGrammarNode.new()
	node.seed_type = spec.get("seed", "icosahedron")
	node.seed_scale = 0.35
	node.base_color = spec.get("color", Color(0.6, 0.7, 0.8))
	node.generations = spec.get("generations", 1)
	node.auto_generate = false  # We'll call generate() after adding rules

	# Parse and add rules
	var rule_defs: Array = spec.get("rules", [])
	for rdef in rule_defs:
		var rule := _create_rule(rdef)
		if rule:
			node.add_rule(rule)

	return node

func _create_rule(rdef: Dictionary) -> MeshRule:
	var op: String = rdef.get("op", "")
	var selector_str: String = rdef.get("selector", "all")
	var rule_params: Dictionary = rdef.get("params", {})

	var sel := _parse_selector(selector_str)

	match op:
		"extrude":
			return ExtrudeFaceOp.new(sel, rule_params)
		"bulge":
			return BulgeOp.new(sel, rule_params)
		"tube_branch":
			return TubeBranchOp.new(sel, rule_params)
		"inset":
			return InsetFaceOp.new(sel, rule_params)
		"split":
			return SplitFaceOp.new(sel, rule_params)
		"delete":
			return DeleteFaceOp.new(sel, rule_params)
		"noise":
			return NoiseDisplaceOp.new(sel, rule_params)
		"scale":
			return ScaleFaceOp.new(sel, rule_params)
		"rotate":
			return RotateFaceOp.new(sel, rule_params)
	return null

func _parse_selector(s: String) -> MeshSelector:
	match s:
		"all":
			return MeshSelector.all_faces()
		"up":
			return MeshSelector.by_normal_direction(Vector3.UP, 60.0)
		"down":
			return MeshSelector.by_normal_direction(Vector3.DOWN, 60.0)
		"up_random":
			return MeshSelector.by_normal_direction(Vector3.UP, 60.0).and_also(
				MeshSelector.by_random(0.25))
		_:
			# Parse "random:0.3", "tag:something", "depth:0-3"
			if s.begins_with("random:"):
				var prob := float(s.substr(7))
				return MeshSelector.by_random(prob)
			elif s.begins_with("tag:"):
				var tag := s.substr(4)
				return MeshSelector.by_tag(tag)
			elif s.begins_with("depth:"):
				var parts := s.substr(6).split("-")
				var min_d := int(parts[0])
				var max_d := int(parts[1]) if parts.size() > 1 else -1
				return MeshSelector.by_depth(min_d, max_d)
	return MeshSelector.all_faces()
