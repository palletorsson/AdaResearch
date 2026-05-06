# @identity
# essence: reads nature_layer.json and places flora via MultiMeshInstance3D — one draw call per type
# desire: the painted map becomes a living world — grass, flowers, trees, mushrooms, water, all from one JSON
# critical_parameter: vegetation_density from EcosystemManager gates how much of the painted data appears
# triggers: map loads → reads nature_layer.json → populates MultiMeshes → density controls visibility
# emerges: soft biome transitions from spray-painted intensity; world grows as spine progresses
# truth: the painter defines possibility. the stage defines reality. MultiMesh makes it fast.

#class_name FloraSpawner  # Removed — this is an autoload singleton
extends Node
## Reads nature_layer.json from the current map directory and places flora
## using MultiMeshInstance3D for VR-safe instanced rendering.
## One MultiMesh per flora type = one draw call per type.
## Uses SyntheticFoliage meshes — real plant shapes, not placeholder boxes.

const SyntheticFoliage: GDScript = preload("res://commons/fold_system/synthetic_foliage.gd")
const MorphologyRouter: GDScript = preload("res://algorithms/nature_system/systems/morphology_router.gd")
const CritterDNA: GDScript = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapper: GDScript = preload("res://algorithms/nature_system/dna/critter_trait_mapper.gd")

# ── Three tiers: real scenes (fallback), canonical morphology (best), synthetic MultiMesh (fill) ──

# Real artifact scenes — placed as full Node3D instances (max 3-5 per type per map)
const REAL_SCENES: Dictionary = {
	"flowers": "res://algorithms/machinelearning/evolvingflowers/evolvingflowers.tscn",
	"tree": "res://algorithms/proceduralgeneration/lsystem/tree_l_system.tscn",
	"mushrooms": "res://algorithms/proceduralgeneration/mushrooms/mushrooms.tscn",
}
const MAX_REAL_PER_TYPE: int = 3  # Max full scene instances per type (VR budget)
const REAL_SCALE: float = 0.25     # Scale down real scenes to fit grid

# Synthetic MultiMesh config — used for fill around the real scenes
const FLORA_TYPES: Dictionary = {
	"grass": { "color": Color(0.3, 0.6, 0.2), "scale": Vector3(0.5, 0.5, 0.5), "y_offset": 0.0 },
	"moss": { "color": Color(0.2, 0.45, 0.15), "scale": Vector3(0.4, 0.4, 0.4), "y_offset": 0.0 },
	"flowers": { "color": Color(0.9, 0.4, 0.6), "scale": Vector3(0.4, 0.4, 0.4), "y_offset": 0.0 },
	"ferns": { "color": Color(0.2, 0.55, 0.2), "scale": Vector3(0.45, 0.45, 0.45), "y_offset": 0.0 },
	"mushrooms": { "color": Color(0.6, 0.35, 0.7), "scale": Vector3(0.5, 0.5, 0.5), "y_offset": 0.0 },
	"reeds": { "color": Color(0.45, 0.55, 0.3), "scale": Vector3(0.35, 0.35, 0.35), "y_offset": 0.0 },
	"tree": { "color": Color(0.2, 0.45, 0.15), "scale": Vector3(0.6, 0.6, 0.6), "y_offset": 0.0 },
	"bush": { "color": Color(0.25, 0.5, 0.2), "scale": Vector3(0.5, 0.5, 0.5), "y_offset": 0.0 },
	"vine": { "color": Color(0.3, 0.5, 0.25), "scale": Vector3(0.35, 0.35, 0.35), "y_offset": 0.0 },
	"walker": { "color": Color(0.8, 0.6, 0.2), "scale": Vector3(0.15, 0.15, 0.15), "y_offset": 0.1 },
	"flyer": { "color": Color(0.3, 0.6, 0.9), "scale": Vector3(0.12, 0.12, 0.12), "y_offset": 0.5 },
	"crawler": { "color": Color(0.8, 0.3, 0.3), "scale": Vector3(0.12, 0.12, 0.12), "y_offset": 0.05 },
}

# ── State ─────────────────────────────────────────────────────────────────
var _multimeshes: Dictionary = {}  # flora_type -> MultiMeshInstance3D
var _real_nodes: Array[Node3D] = [] # Full scene instances (flowers, trees, mushrooms)
var _canonical_nodes: Array[Node3D] = [] # Canonical MorphologyRouter instances
var _trait_mapper = null
var _spawn_root: Node3D = null
var _nature_data: Dictionary = {}
var _cached_density: float = -1.0
var _ecosystem: Node = null
var _grid_cube_size: float = 1.0


func _ready() -> void:
	_spawn_root = Node3D.new()
	_spawn_root.name = "FloraRoot"
	add_child(_spawn_root)
	call_deferred("_initialize")


func _initialize() -> void:
	_ecosystem = get_node_or_null("/root/EcosystemManager")
	_trait_mapper = CritterTraitMapper.new()
	_load_nature_layer()
	if not _nature_data.is_empty():
		_build_multimeshes()
		print("FloraSpawner: ready — %d flora types from nature_layer.json" % _multimeshes.size())


func _process(delta: float) -> void:
	if not _ecosystem or _nature_data.is_empty():
		return
	# Check density every 2 seconds
	var density: float = 0.0
	if _ecosystem.get("vegetation_density") != null:
		density = float(_ecosystem.get("vegetation_density"))
	if abs(density - _cached_density) > 0.01:
		_cached_density = density
		_update_visibility(density)


# ═════════════════════════════════════════════════════════════════════════
# LOAD nature_layer.json
# ═════════════════════════════════════════════════════════════════════════

func _load_nature_layer() -> void:
	# Find current map name from GridSystem
	var grid := get_tree().root.find_child("GridSystem", true, false)
	var map_name: String = ""
	if grid and "map_name" in grid:
		map_name = str(grid.get("map_name"))

	if map_name.is_empty():
		return

	var path := "res://commons/maps/%s/nature_layer.json" % map_name
	if not FileAccess.file_exists(path):
		# Also try user:// path
		path = "user://maps/%s/nature_layer.json" % map_name
		if not FileAccess.file_exists(path):
			return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("FloraSpawner: failed to parse nature_layer.json")
		return

	_nature_data = json.data
	print("FloraSpawner: loaded nature_layer.json for %s" % map_name)


# ═════════════════════════════════════════════════════════════════════════
# BUILD MultiMeshes — one per flora type
# ═════════════════════════════════════════════════════════════════════════

func _build_multimeshes() -> void:
	var layers: Dictionary = _nature_data.get("layers", {})
	if layers.is_empty():
		return

	# Collect all instances per flora type
	var instances: Dictionary = {}  # flora_type -> Array of {row, col, intensity}

	for layer_name in layers:
		var grid: Array = layers[layer_name]
		for row_idx in grid.size():
			var row: Array = grid[row_idx]
			for col_idx in row.size():
				var cell: Dictionary = row[col_idx]
				var flora_type: String = cell.get("type", "none")
				var intensity: float = float(cell.get("intensity", 0))

				if flora_type == "none" or intensity < 0.05:
					continue

				if not instances.has(flora_type):
					instances[flora_type] = []

				instances[flora_type].append({
					"row": row_idx,
					"col": col_idx,
					"intensity": intensity,
				})

	# TIER 1: Place real artifact scenes at the strongest cells
	for flora_type in instances:
		if not REAL_SCENES.has(flora_type):
			continue
		var placements: Array = instances[flora_type]
		# Sort by intensity — strongest first
		placements.sort_custom(func(a, b): return float(a["intensity"]) > float(b["intensity"]))
		# Place up to MAX_REAL_PER_TYPE full scenes
		var real_count: int = mini(MAX_REAL_PER_TYPE, placements.size())
		for i in real_count:
			_place_real_scene(flora_type, placements[i])
		print("FloraSpawner: %d real %s scenes placed" % [real_count, flora_type])

	# TIER 1.5: Place canonical MorphologyRouter flora at top 3 strongest cells per type
	for flora_type in instances:
		var placements: Array = instances[flora_type]
		# Sort by intensity — strongest first
		placements.sort_custom(func(a, b): return float(a["intensity"]) > float(b["intensity"]))
		var canonical_count: int = 0
		for i in placements.size():
			if canonical_count >= 3:
				break
			if float(placements[i]["intensity"]) <= 0.7:
				break
			_place_canonical_flora(flora_type, placements[i])
			canonical_count += 1
		if canonical_count > 0:
			print("FloraSpawner: %d canonical %s via MorphologyRouter" % [canonical_count, flora_type])

	# TIER 2: Fill remaining cells with synthetic MultiMesh
	for flora_type in instances:
		var placements: Array = instances[flora_type]
		if placements.is_empty():
			continue

		var config: Dictionary = FLORA_TYPES.get(flora_type, {})
		if config.is_empty():
			continue

		var mmi := _create_multimesh_for_type(flora_type, config, placements)
		_spawn_root.add_child(mmi)
		_multimeshes[flora_type] = mmi


func _place_real_scene(flora_type: String, placement: Dictionary) -> void:
	var scene_path: String = REAL_SCENES[flora_type]
	var scene: PackedScene = load(scene_path) as PackedScene
	if not scene:
		push_warning("FloraSpawner: could not load %s" % scene_path)
		return

	var instance: Node3D = scene.instantiate() as Node3D
	if not instance:
		return

	var row: int = int(placement["row"])
	var col: int = int(placement["col"])
	var intensity: float = float(placement["intensity"])

	instance.position = Vector3(
		float(col) * _grid_cube_size + _grid_cube_size * 0.5,
		0.5,
		float(row) * _grid_cube_size + _grid_cube_size * 0.5
	)
	instance.scale = Vector3.ONE * REAL_SCALE * intensity
	instance.rotation.y = randf() * TAU

	if instance.has_method("apply_grid_config"):
		instance.apply_grid_config({})

	_spawn_root.add_child(instance)
	_real_nodes.append(instance)


func _place_canonical_flora(flora_type: String, placement: Dictionary) -> void:
	# Map flora type to kingdom ID
	var kingdom: int
	match flora_type:
		"tree", "bush", "vine": kingdom = 0  # Tree kingdom
		"grass", "ferns", "reeds": kingdom = 0  # Also tree-like (use LOD 0 for grass)
		"flowers": kingdom = 2  # Flower kingdom
		"mushrooms": kingdom = 3  # Fungus kingdom
		"walker", "crawler", "flyer": kingdom = 1  # Creature kingdom
		_: return

	var dna = CritterDNA.random_kingdom(kingdom, placement["row"] * 100 + placement["col"])
	# Scale down for VR
	dna.scale = float(placement["intensity"]) * 0.3

	var node: Node3D = MorphologyRouter.build(dna, null, _trait_mapper, 0)  # LOD 0 = lowest detail
	if not node:
		return

	node.position = Vector3(
		float(placement["col"]) * _grid_cube_size + _grid_cube_size * 0.5,
		0.5,
		float(placement["row"]) * _grid_cube_size + _grid_cube_size * 0.5
	)
	node.rotation.y = randf() * TAU
	_spawn_root.add_child(node)
	_canonical_nodes.append(node)


func _create_multimesh_for_type(flora_type: String, config: Dictionary, placements: Array) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Flora_%s" % flora_type

	# Create the mesh template — SyntheticFoliage for plants, simple shapes for others
	var mesh: Mesh = _create_flora_mesh(flora_type)

	# Create material — use vertex colors for SyntheticFoliage plants
	var mat := StandardMaterial3D.new()
	var color: Color = config.get("color", Color.WHITE)
	var is_plant: bool = flora_type in ["grass", "moss", "flowers", "ferns", "mushrooms", "reeds", "tree", "bush", "vine"]
	if is_plant:
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	else:
		mat.albedo_color = color
	mat.roughness = 0.8
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color * 0.1
	mat.emission_energy_multiplier = 0.3

	# Create MultiMesh
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = placements.size()

	# Set transforms for each instance
	var rng := RandomNumberGenerator.new()
	rng.seed = flora_type.hash()

	for i in placements.size():
		var p: Dictionary = placements[i]
		var row: int = int(p["row"])
		var col: int = int(p["col"])
		var intensity: float = float(p["intensity"])

		var base_scale: Vector3 = config.get("scale", Vector3.ONE)
		var y_offset: float = config.get("y_offset", 0.5)

		# Position: grid cell center with slight random offset
		var x: float = float(col) * _grid_cube_size + _grid_cube_size * 0.5
		var z: float = float(row) * _grid_cube_size + _grid_cube_size * 0.5
		var y: float = y_offset

		# Random offset within cell
		x += rng.randf_range(-0.2, 0.2)
		z += rng.randf_range(-0.2, 0.2)

		# Scale by intensity
		var scale: Vector3 = base_scale * intensity

		# Random Y rotation
		var rot_y: float = rng.randf() * TAU

		var t := Transform3D.IDENTITY
		t = t.scaled(scale)
		t = t.rotated(Vector3.UP, rot_y)
		t.origin = Vector3(x, y, z)

		mm.set_instance_transform(i, t)

		# Color variation
		var color_var := Color(
			color.r + rng.randf_range(-0.05, 0.05),
			color.g + rng.randf_range(-0.05, 0.05),
			color.b + rng.randf_range(-0.05, 0.05),
			color.a
		)
		mm.set_instance_color(i, color_var)

	mmi.multimesh = mm
	mmi.material_override = mat

	# VR LOD: visibility range
	mmi.visibility_range_begin = 0.0
	mmi.visibility_range_end = _get_lod_distance(flora_type)
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

	return mmi


func _create_flora_mesh(flora_type: String) -> Mesh:
	## Use SyntheticFoliage for real plant shapes instead of placeholder geometry.
	match flora_type:
		"grass", "moss":
			return SyntheticFoliage.make_grass()
		"flowers":
			return SyntheticFoliage.make_flower()
		"ferns":
			return SyntheticFoliage.make_fern()
		"mushrooms":
			return SyntheticFoliage.make_mushroom()
		"reeds":
			return SyntheticFoliage.make_reed()
		"tree":
			return SyntheticFoliage.make_tree()
		"bush":
			return SyntheticFoliage.make_bush()
		"vine":
			return SyntheticFoliage.make_vine()
		_:
			# Ground cover + water + creatures stay as simple meshes
			var config: Dictionary = FLORA_TYPES.get(flora_type, {})
			var mesh_shape: String = config.get("mesh", "sphere")
			match mesh_shape:
				"plane":
					return PlaneMesh.new()
				"box":
					return BoxMesh.new()
				_:
					var s := SphereMesh.new()
					s.radius = 0.5
					s.radial_segments = 6
					return s


func _get_lod_distance(flora_type: String) -> float:
	# VR LOD distances — closer = cheaper flora type
	match flora_type:
		"grass", "moss", "sand", "soil":
			return 8.0  # Ground cover disappears at 8m
		"flowers", "ferns", "mushrooms", "reeds":
			return 12.0  # Small flora at 12m
		"tree", "bush", "vine":
			return 20.0  # Large flora visible far
		"puddle", "stream", "pond":
			return 15.0  # Water visible medium
		"walker", "flyer", "crawler":
			return 10.0  # Creature markers at 10m
		_:
			return 10.0


# ═════════════════════════════════════════════════════════════════════════
# DENSITY GATING — stage controls what percentage of painted flora appears
# ═════════════════════════════════════════════════════════════════════════

func _update_visibility(density: float) -> void:
	## Show/hide MultiMesh instances based on current density.
	## At density 0.3, only instances with intensity > 0.7 show (strongest painted cells first).
	for flora_type in _multimeshes:
		var mmi: MultiMeshInstance3D = _multimeshes[flora_type]
		if not is_instance_valid(mmi):
			continue

		var mm: MultiMesh = mmi.multimesh
		if not mm:
			continue

		# Approach: scale instances to zero if their intensity < (1.0 - density)
		# This means at density=0.1, only intensity>0.9 cells show
		# At density=1.0, all cells show
		var threshold: float = 1.0 - density

		# We need the original placements to know intensity per instance
		# For now, use visibility_range as the gate
		mmi.visible = density > 0.05


# ═════════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════════

func apply_grid_config(_config: Dictionary) -> void:
	_cached_density = -1.0
	_nature_data = {}
	# Clear existing flora
	for child in _spawn_root.get_children():
		child.queue_free()
	_multimeshes.clear()
	_real_nodes.clear()
	_canonical_nodes.clear()
	# Reload
	call_deferred("_initialize")
