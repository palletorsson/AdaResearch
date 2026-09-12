# @identity
# essence: P(x,z) = noise(x,z) > threshold → spawn — noise-driven spatial Poisson process
# desire: wander through a procedural mushroom meadow where fairy rings and clusters emerge from noise
# critical_parameter: mushroom_density — controls expected count per unit area; interacts with FastNoiseLite clearing threshold
# triggers: generate_mushroom_positions() uses noise to create natural clearings; create_mushroom_patterns() adds fairy rings and clusters
# emerges: fairy rings form perfect circles of identical species — order self-organizing within the random field
# needs: random ground height grid [has]; 5 mushroom templates + glowing variant [has]; VR controls [missing]
# relationships: feeds Random_Mushrooms map alongside random_number_book_page_collection; contrasts with pheromone_terrain (static vs dynamic growth)
# truth: A mushroom meadow is randomness that has found a niche — noise filtered through ecology.

extends Node3D

# Configuration
@export var meadow_size: float = 10.0
@export var mushroom_count: int = 100
@export var mushroom_density: float = 0.8
@export var mushroom_variety: int = 5
@export var add_glowing_mushrooms: bool = true
@export var add_ground_cover: bool = true
@export var use_random_ground: bool = true
@export var ground_random_amplitude: float = 0.18
@export var ground_resolution: int = 36
@export var ground_seed: int = 0
@export var ground_albedo_color: Color = Color(0.44, 0.56, 0.34)  # Lighter green forest floor
@export_range(0.0, 1.0, 0.01) var glowing_mushroom_spawn_chance: float = 0.22
@export var glowing_mushroom_body_color: Color = Color(0.2, 0.88, 0.38)
@export var glowing_mushroom_glow_color: Color = Color(0.95, 0.12, 0.12)
@export var glowing_mushroom_light_energy: float = 0.9

## THE SPECIMEN TABLE (waves / randomness / noise, R4, 2026-09-12) — an opt-in staging. The
## meadow is an ARRANGEMENT made once from draws: six templates, candidates scattered and
## accepted or rejected by a noise clearing, a template, a yaw and a size for each, then rings
## and clusters built on purpose. `#stand:specimen` raises the meadow as a bed (its ground
## lifted clear of the museum deck, a kerb around it) and stands a table at its north edge
## with the six templates as type specimens, a housed readout of those decisions, SHOW (ring
## every instance of one template in the bed), KIND (scattered · rings · clusters · rejected
## candidates), SIZE (the size rule off under the same seed), REGROW (the same population
## again) and NEW SEED. Under the table the bed grows from a NAMED population seed that covers
## every draw and the ground. `stand:none` (the default) builds nothing of this.
##
##   "mushrooms:180#stand:specimen#size:6"          a six-metre bed with its table, its own seed
##   "mushrooms:180#stand:specimen#size:6#seed:777"   the same with a pinned seed
@export_enum("none", "specimen") var stand: String = "none"
## The population seed. -1 (the default) draws from the global stream exactly as before —
## the same calls in the same order. Non-negative: a private generator makes every draw of
## the build, and the ground's generator takes seed + 1 unless ground_seed says otherwise.
@export var population_seed: int = -1
## The size rule: scattered 0.7–1.3, rings 0.8–1.2, clusters 0.5–1.2. Off, every mushroom
## stands at scale 1 and the draws are still made, so the rest of the population is unchanged.
@export var size_variation: bool = true
## Glowing mushrooms carry an OmniLight each; past this many the light is switched off and the
## cap keeps its emissive glow. 0 = no cap (shipped); the stand sets 12 unless told otherwise.
@export var max_glow_lights: int = 0
## Lifts the ground, the mushrooms and the ground cover by this much, so a ground that
## undulates ±amplitude around 0 stands clear of a floor at 0. 0 = as shipped; the stand
## sets ground_random_amplitude unless told otherwise.
@export var bed_lift: float = 0.0
var _pop_rng: RandomNumberGenerator = null
var _candidates_requested: int = 0
var _rejected: PackedVector3Array = PackedVector3Array()
var _rings: Array = []
var _clusters: Array = []
var _lit_lights: int = 0
var _glow_instances: int = 0
var _stand_root: Node3D
var _kerb: Node3D
var _readout: Label3D
var _panel: Node3D
var _highlight_mmi: MultiMeshInstance3D
var _pins_mmi: MultiMeshInstance3D
var _specimen_slots: Array = []
var _show_template: int = 0
var _kind: int = 0
const KINDS: PackedStringArray = ["template", "scattered", "rings", "clusters", "rejected"]
const TABLE_W: float = 1.50
const TABLE_D: float = 0.50
const TABLE_H: float = 0.90
const TABLE_GAP: float = 0.90        # from the bed's edge to the table's near edge
var _built: bool = false

# References
var mushroom_types = []
var mushrooms = []
var ground = null
var ground_height_grid: PackedFloat32Array = PackedFloat32Array()
var ground_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	if stand == "specimen":
		_prepare_stand()
	_seed_generators()

	# Create the ground first
	create_ground()
	
	# Create mushroom templates
	create_mushroom_templates()
	
	# Place mushrooms
	generate_mushroom_field()
	
	# Add ambient lighting
	create_ambient_lighting()
	
	# Add ground details
	if add_ground_cover:
		add_ground_details()
	_lift_bed()
	_built = true
	_apply_stand()


## What the stand needs before the first build: a NAMED seed a visitor can read and repeat
## (from a private generator, never the global stream), a cap on the lights, the bed lifted.
func _prepare_stand() -> void:
	if population_seed < 0:
		var r := RandomNumberGenerator.new()
		r.randomize()
		population_seed = r.randi_range(10000, 99999)
	if max_glow_lights == 0:
		max_glow_lights = 12
	if bed_lift == 0.0:
		bed_lift = ground_random_amplitude


## The two generators, as shipped (the ground's randomized or seeded, the population on the
## global stream) or, under a population seed, both private and replayable.
func _seed_generators() -> void:
	if population_seed >= 0:
		_pop_rng = RandomNumberGenerator.new()
		_pop_rng.seed = population_seed
		if ground_seed == 0:
			ground_rng.seed = population_seed + 1
		else:
			ground_rng.seed = ground_seed
	else:
		_pop_rng = null
		if ground_seed == 0:
			ground_rng.randomize()
		else:
			ground_rng.seed = ground_seed


## THE ONLY DRAWS OF THE BUILD. population_seed = -1 falls straight through to the global
## randf() / randi(), same call, same order — the shipped meadow is unchanged.
func _rf() -> float:
	return _pop_rng.randf() if _pop_rng != null else randf()

func _ri() -> int:
	return _pop_rng.randi() if _pop_rng != null else randi()

## The size rule, or scale 1 with the draw still made.
func _size(v: float) -> float:
	return v if size_variation else 1.0

## The ground, the mushrooms and the ground cover up by bed_lift (0 as shipped).
func _lift_bed() -> void:
	for nm in ["Ground", "MushroomField", "Grass", "Rocks", "FallenLeaves"]:
		var n: Node = get_node_or_null(nm)
		if n is Node3D:
			(n as Node3D).position.y = bed_lift

func create_ground() -> void:
	# Create a procedural ground
	ground = Node3D.new()
	ground.name = "Ground"
	
	var static_body = StaticBody3D.new()
	static_body.name = "GroundStaticBody"
	ground.add_child(static_body)
	
	# Add a mesh for the ground
	var ground_mesh = MeshInstance3D.new()
	ground_mesh.name = "GroundMesh"
	ground_mesh.mesh = _build_ground_mesh()
	
	# Create ground material
	var material = StandardMaterial3D.new()
	material.albedo_color = ground_albedo_color
	material.roughness = 0.9
	ground_mesh.material_override = material

	# Add walkable collision from the actual surface mesh
	var collision = CollisionShape3D.new()
	collision.name = "GroundCollision"
	if ground_mesh.mesh:
		collision.shape = ground_mesh.mesh.create_trimesh_shape()
	else:
		var fallback = BoxShape3D.new()
		fallback.size = Vector3(meadow_size, 0.1, meadow_size)
		collision.shape = fallback

	static_body.add_child(ground_mesh)
	static_body.add_child(collision)
	
	# Add to scene
	add_child(ground)

func _build_ground_mesh() -> ArrayMesh:
	var plane = PlaneMesh.new()
	plane.size = Vector2(meadow_size, meadow_size)
	plane.subdivide_depth = maxi(1, ground_resolution)
	plane.subdivide_width = maxi(1, ground_resolution)

	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(plane, 0)
	var base_mesh: ArrayMesh = surface_tool.commit()
	if base_mesh.get_surface_count() == 0:
		return base_mesh

	var arrays = base_mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var grid_res := maxi(1, ground_resolution)
	var grid_size := grid_res + 1
	ground_height_grid = PackedFloat32Array()
	ground_height_grid.resize(grid_size * grid_size)

	for i in range(vertices.size()):
		var v = vertices[i]
		var height := 0.0
		if use_random_ground:
			# RandomSpace-style random heights (no coherent noise field).
			height = ground_rng.randf_range(-ground_random_amplitude, ground_random_amplitude)
		vertices[i].y = height

		var gx = int(round(((v.x / meadow_size) + 0.5) * grid_res))
		var gz = int(round(((v.z / meadow_size) + 0.5) * grid_res))
		gx = clampi(gx, 0, grid_res)
		gz = clampi(gz, 0, grid_res)
		ground_height_grid[gz * grid_size + gx] = height

	var normals := _calculate_vertex_normals(vertices, indices)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals

	var out_mesh = ArrayMesh.new()
	out_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out_mesh

func _calculate_vertex_normals(vertices: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	for i in range(normals.size()):
		normals[i] = Vector3.ZERO

	if indices.is_empty():
		for i in range(normals.size()):
			normals[i] = Vector3.UP
		return normals

	for i in range(0, indices.size(), 3):
		var i0: int = indices[i]
		var i1: int = indices[i + 1]
		var i2: int = indices[i + 2]
		if i0 >= vertices.size() or i1 >= vertices.size() or i2 >= vertices.size():
			continue

		var edge1 = vertices[i1] - vertices[i0]
		var edge2 = vertices[i2] - vertices[i0]
		var face_normal = edge1.cross(edge2)
		if face_normal.length_squared() > 0.000001:
			face_normal = face_normal.normalized()
		else:
			face_normal = Vector3.UP

		normals[i0] += face_normal
		normals[i1] += face_normal
		normals[i2] += face_normal

	for i in range(normals.size()):
		if normals[i].length_squared() > 0.000001:
			normals[i] = normals[i].normalized()
		else:
			normals[i] = Vector3.UP
		if normals[i].y < 0.0:
			normals[i] = -normals[i]

	return normals

func create_mushroom_templates() -> void:
	# Create different mushroom types
	for i in range(mushroom_variety):
		var template = create_mushroom_template(i)
		mushroom_types.append(template)
	
	# Create special glowing mushrooms if enabled
	if add_glowing_mushrooms:
		var glowing_mushroom = create_glowing_mushroom()
		mushroom_types.append(glowing_mushroom)

func create_mushroom_template(type_index):
	# Create a mushroom base node
	var mushroom = Node3D.new()
	mushroom.name = "Mushroom_Template_" + str(type_index)
	
	# Different types of mushrooms
	match type_index:
		0: create_standard_mushroom(mushroom, 0.2, 0.15, Color(0.8, 0.6, 0.4))  # Tan mushroom
		1: create_standard_mushroom(mushroom, 0.15, 0.1, Color(0.8, 0.2, 0.2))  # Red mushroom
		2: create_flat_cap_mushroom(mushroom, 0.25, Color(0.5, 0.4, 0.3))       # Brown flat mushroom
		3: create_tall_thin_mushroom(mushroom, 0.35, Color(0.9, 0.9, 0.8))      # Tall white mushroom
		4: create_puffball_mushroom(mushroom, 0.12, Color(0.9, 0.9, 0.85))      # White puffball
	
	return mushroom

func create_standard_mushroom(mushroom, cap_size, stem_height, color) -> void:
	# Create stem
	var stem = MeshInstance3D.new()
	stem.name = "Stem"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = cap_size * 0.2
	cylinder.bottom_radius = cap_size * 0.25
	cylinder.height = stem_height
	cylinder.radial_segments = 8
	stem.mesh = cylinder
	
	var stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = color.lightened(0.3)  # Lighter stem
	stem.material_override = stem_material
	
	# Position stem
	stem.position.y = stem_height / 2
	
	# Create cap
	var cap = MeshInstance3D.new()
	cap.name = "Cap"
	
	var hemisphere = SphereMesh.new()
	hemisphere.radius = cap_size
	hemisphere.height = cap_size * 1.2
	hemisphere.radial_segments = 16
	hemisphere.rings = 8
	cap.mesh = hemisphere
	
	# Flatten the bottom of the cap
	cap.scale.y = 0.5
	
	# Position cap on top of stem
	cap.position.y = stem_height
	
	var cap_material = StandardMaterial3D.new()
	cap_material.albedo_color = color
	cap.material_override = cap_material
	
	# Add to mushroom
	mushroom.add_child(stem)
	mushroom.add_child(cap)
	
	# Add gills under cap
	add_gills(mushroom, cap_size, stem_height, color)

func add_gills(mushroom, cap_size, stem_height, color) -> void:
	var gills = MeshInstance3D.new()
	gills.name = "Gills"
	
	var disc = CylinderMesh.new()
	disc.top_radius = cap_size * 0.95
	disc.bottom_radius = cap_size * 0.95
	disc.height = 0.01
	disc.radial_segments = 16
	gills.mesh = disc
	
	# Position gills under cap
	gills.position.y = stem_height - 0.01
	
	var gill_material = StandardMaterial3D.new()
	gill_material.albedo_color = color.darkened(0.3)  # Darker gills
	gills.material_override = gill_material
	
	mushroom.add_child(gills)

func create_flat_cap_mushroom(mushroom, cap_size, color) -> void:
	# Create stem
	var stem = MeshInstance3D.new()
	stem.name = "Stem"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = cap_size * 0.15
	cylinder.bottom_radius = cap_size * 0.2
	cylinder.height = cap_size * 0.6
	cylinder.radial_segments = 8
	stem.mesh = cylinder
	
	var stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = color.lightened(0.2)
	stem.material_override = stem_material
	
	# Position stem
	stem.position.y = (cap_size * 0.6) / 2
	
	# Create flat cap
	var cap = MeshInstance3D.new()
	cap.name = "Cap"
	
	var disc = CylinderMesh.new()
	disc.top_radius = cap_size
	disc.bottom_radius = cap_size
	disc.height = cap_size * 0.2
	disc.radial_segments = 16
	cap.mesh = disc
	
	# Position cap on top of stem
	cap.position.y = cap_size * 0.6
	
	var cap_material = StandardMaterial3D.new()
	cap_material.albedo_color = color
	cap.material_override = cap_material
	
	# Add to mushroom
	mushroom.add_child(stem)
	mushroom.add_child(cap)

func create_tall_thin_mushroom(mushroom, height, color) -> void:
	# Create stem
	var stem = MeshInstance3D.new()
	stem.name = "Stem"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.03
	cylinder.bottom_radius = 0.04
	cylinder.height = height
	cylinder.radial_segments = 8
	stem.mesh = cylinder
	
	var stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = color
	stem.material_override = stem_material
	
	# Position stem
	stem.position.y = height / 2
	
	# Create small cap
	var cap = MeshInstance3D.new()
	cap.name = "Cap"
	
	var cone = CylinderMesh.new()
	cone.top_radius = 0.01
	cone.bottom_radius = 0.06
	cone.height = 0.1
	cone.radial_segments = 8
	cap.mesh = cone
	
	# Position cap on top of stem
	cap.position.y = height + 0.05
	
	var cap_material = StandardMaterial3D.new()
	cap_material.albedo_color = color.darkened(0.1)
	cap.material_override = cap_material
	
	# Add to mushroom
	mushroom.add_child(stem)
	mushroom.add_child(cap)

func create_puffball_mushroom(mushroom, size, color) -> void:
	# Create just a simple sphere for puffball
	var puffball = MeshInstance3D.new()
	puffball.name = "Puffball"
	
	var sphere = SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2
	sphere.radial_segments = 16
	sphere.rings = 8
	puffball.mesh = sphere
	
	# Position slightly buried in ground
	puffball.position.y = size * 0.8
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	puffball.material_override = material
	
	# Add texture/bumps to puffball
	add_puffball_texture(puffball, color)
	
	# Add to mushroom
	mushroom.add_child(puffball)

func add_puffball_texture(puffball, color) -> void:
	# Add small bumps on the puffball surface using MultiMesh
	var bump_count = 12
	var small_sphere = SphereMesh.new()
	small_sphere.radius = 0.02
	small_sphere.height = 0.04
	small_sphere.radial_segments = 6
	small_sphere.rings = 4
	var bump_material = StandardMaterial3D.new()
	bump_material.albedo_color = color.darkened(0.1)
	small_sphere.material = bump_material

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = bump_count
	mm.mesh = small_sphere

	for i in range(bump_count):
		var phi = _rf() * PI * 2
		var theta = _rf() * PI
		var radius = 0.12
		var pos = Vector3(
			radius * sin(theta) * cos(phi),
			radius * sin(theta) * sin(phi),
			radius * cos(theta)
		)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "PuffballBumpsMM"
	mmi.multimesh = mm
	puffball.add_child(mmi)

func create_glowing_mushroom():
	# Create a special glowing mushroom
	var mushroom = Node3D.new()
	mushroom.name = "Mushroom_Template_Glowing"
	
	# Create thin stem
	var stem = MeshInstance3D.new()
	stem.name = "Stem"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.03
	cylinder.height = 0.18
	cylinder.radial_segments = 8
	stem.mesh = cylinder
	
	var stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = glowing_mushroom_body_color.lightened(0.25)
	stem_material.emission_enabled = true
	stem_material.emission = glowing_mushroom_glow_color
	stem_material.emission_energy = glowing_mushroom_light_energy * 0.55
	stem.material_override = stem_material
	
	# Position stem
	stem.position.y = 0.09
	
	# Create glowing cap
	var cap = MeshInstance3D.new()
	cap.name = "Cap"
	
	var dome = SphereMesh.new()
	dome.radius = 0.08
	dome.height = 0.1
	dome.radial_segments = 16
	dome.rings = 8
	cap.mesh = dome
	
	# Flatten into dome shape
	cap.scale.y = 0.6
	
	# Position cap on top of stem
	cap.position.y = 0.18
	
	var cap_material = StandardMaterial3D.new()
	cap_material.albedo_color = glowing_mushroom_body_color
	cap_material.emission_enabled = true
	cap_material.emission = glowing_mushroom_glow_color
	cap_material.emission_energy = glowing_mushroom_light_energy * 2.2
	cap.material_override = cap_material
	
	# Add to mushroom
	mushroom.add_child(stem)
	mushroom.add_child(cap)
	
	# Add glow effect
	var glow = OmniLight3D.new()
	glow.name = "GlowLight"
	glow.light_color = glowing_mushroom_glow_color
	glow.light_energy = glowing_mushroom_light_energy
	glow.omni_range = 1.0
	glow.position.y = 0.2
	mushroom.add_child(glow)
	
	return mushroom

func generate_mushroom_field() -> void:
	# Create a container for all mushrooms
	var field = Node3D.new()
	field.name = "MushroomField"
	add_child(field)
	
	# Generate positions
	var positions = generate_mushroom_positions()
	_rings.clear()
	_clusters.clear()
	_lit_lights = 0
	_glow_instances = 0

	# Place mushrooms
	for i in range(positions.size()):
		var pos = positions[i]

		# Determine mushroom type
		var type_index = _ri() % mushroom_types.size()

		# For glowing mushrooms, use sparingly
		if type_index == mushroom_types.size() - 1 && add_glowing_mushrooms:
			# Spawn chance is configurable so scenes can push denser glowing patches.
			if _rf() > clampf(glowing_mushroom_spawn_chance, 0.0, 1.0):
				type_index = _ri() % (mushroom_types.size() - 1)
		
		# Instantiate mushroom
		var mushroom = mushroom_types[type_index].duplicate()
		mushroom.name = "Mushroom_" + str(i)
		
		# Position mushroom
		mushroom.position = pos
		
		# Randomize rotation and scale
		mushroom.rotation_degrees.y = _rf() * 360
		
		var scale_factor = _size(0.7 + _rf() * 0.6)  # 0.7 to 1.3
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
		mushroom.set_meta("template", type_index)
		mushroom.set_meta("kind", "scattered")

		# Add to field
		field.add_child(mushroom)
		mushrooms.append(mushroom)
		_note_light(mushroom)

	# Organize some mushrooms into fairy rings and clusters
	create_mushroom_patterns()

func generate_mushroom_positions():
	var positions = []
	
	# Distribute based on meadow size and density
	var area = meadow_size * meadow_size
	var target_count = mushroom_count * mushroom_density
	
	# Create a noise generator for distribution
	var noise = FastNoiseLite.new()
	noise.seed = _ri()
	noise.frequency = 0.5
	
	# Generate positions
	_candidates_requested = int(target_count)
	_rejected = PackedVector3Array()
	for _i in range(target_count):
		var pos_x = _rf() * meadow_size - meadow_size / 2
		var pos_z = _rf() * meadow_size - meadow_size / 2

		# Use noise to make distribution more natural
		var noise_val = noise.get_noise_2d(pos_x * 2, pos_z * 2)

		# Skip if noise value is too low (creates natural clearings)
		if noise_val < -0.3:
			_rejected.append(Vector3(pos_x, get_ground_height(pos_x, pos_z), pos_z))
			continue

		# Get ground height at this position
		var ground_height = get_ground_height(pos_x, pos_z)
		
		positions.append(Vector3(pos_x, ground_height, pos_z))
	
	return positions

func get_ground_height(x: float, z: float) -> float:
	if not use_random_ground or ground_height_grid.is_empty():
		return 0.0

	var grid_res: int = maxi(1, ground_resolution)
	var grid_size: int = grid_res + 1

	var u: float = ((x / meadow_size) + 0.5) * float(grid_res)
	var v: float = ((z / meadow_size) + 0.5) * float(grid_res)
	u = clampf(u, 0.0, float(grid_res))
	v = clampf(v, 0.0, float(grid_res))

	var x0: int = int(floor(u))
	var z0: int = int(floor(v))
	var x1: int = mini(x0 + 1, grid_res)
	var z1: int = mini(z0 + 1, grid_res)
	var tx: float = u - float(x0)
	var tz: float = v - float(z0)

	var h00: float = ground_height_grid[z0 * grid_size + x0]
	var h10: float = ground_height_grid[z0 * grid_size + x1]
	var h01: float = ground_height_grid[z1 * grid_size + x0]
	var h11: float = ground_height_grid[z1 * grid_size + x1]

	var h0: float = lerpf(h00, h10, tx)
	var h1: float = lerpf(h01, h11, tx)
	return lerpf(h0, h1, tz)

func create_mushroom_patterns() -> void:
	# Create fairy rings
	var ring_count = int(meadow_size / 5)
	
	for _i in range(ring_count):
		create_fairy_ring()
	
	# Create clusters
	var cluster_count = int(meadow_size / 3)
	
	for _i in range(cluster_count):
		create_mushroom_cluster()

func create_fairy_ring() -> void:
	# Choose a random center point
	var center_x = _rf() * meadow_size - meadow_size / 2
	var center_z = _rf() * meadow_size - meadow_size / 2
	
	# Choose a radius
	var radius = 1.0 + _rf() * 2.0
	
	# Choose a mushroom type for the ring
	var type_index = _ri() % (mushroom_types.size() - (1 if add_glowing_mushrooms else 0))
	
	# Number of mushrooms in the ring
	var count = int(radius * 8)
	var ring_record := {"template": type_index, "radius": radius, "centre": [center_x, center_z], "requested": count, "placed": 0}
	_rings.append(ring_record)

	for i in range(count):
		var angle = (2.0 * PI / count) * i
		var pos_x = center_x + cos(angle) * radius
		var pos_z = center_z + sin(angle) * radius
		
		# Skip if outside meadow
		if abs(pos_x) > meadow_size / 2 or abs(pos_z) > meadow_size / 2:
			continue
		
		# Get ground height
		var ground_height = get_ground_height(pos_x, pos_z)
		
		# Create mushroom
		var mushroom = mushroom_types[type_index].duplicate()
		mushroom.name = "FairyRing_Mushroom_" + str(i)
		
		# Position and rotate
		mushroom.position = Vector3(pos_x, ground_height, pos_z)
		mushroom.rotation_degrees.y = _rf() * 360
		
		# Slightly varied scale
		var scale_factor = _size(0.8 + _rf() * 0.4)
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
		mushroom.set_meta("template", type_index)
		mushroom.set_meta("kind", "ring")
		mushroom.set_meta("group", _rings.size() - 1)
		ring_record["placed"] += 1

		# Add to scene
		get_node("MushroomField").add_child(mushroom)
		mushrooms.append(mushroom)
		_note_light(mushroom)

func create_mushroom_cluster() -> void:
	# Choose a random center point
	var center_x = _rf() * meadow_size - meadow_size / 2
	var center_z = _rf() * meadow_size - meadow_size / 2
	
	# Choose cluster size
	var cluster_size = 0.5 + _rf() * 1.0
	
	# Choose a mushroom type for the cluster
	var type_index = _ri() % mushroom_types.size()
	
	# Number of mushrooms in the cluster
	var count = 5 + _ri() % 10
	var cluster_record := {"template": type_index, "size": cluster_size, "centre": [center_x, center_z], "requested": count, "placed": 0}
	_clusters.append(cluster_record)

	for _i in range(count):
		var angle = _rf() * PI * 2
		var distance = _rf() * cluster_size
		
		var pos_x = center_x + cos(angle) * distance
		var pos_z = center_z + sin(angle) * distance
		
		# Skip if outside meadow
		if abs(pos_x) > meadow_size / 2 or abs(pos_z) > meadow_size / 2:
			continue
		
		# Get ground height
		var ground_height = get_ground_height(pos_x, pos_z)
		
		# Create mushroom
		var mushroom = mushroom_types[type_index].duplicate()
		mushroom.name = "Cluster_Mushroom_" + str(_i)
		
		# Position and rotate
		mushroom.position = Vector3(pos_x, ground_height, pos_z)
		mushroom.rotation_degrees.y = _rf() * 360
		
		# Varied scale - smaller ones more common in clusters
		var scale_factor = _size(0.5 + _rf() * 0.7)
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
		mushroom.set_meta("template", type_index)
		mushroom.set_meta("kind", "cluster")
		mushroom.set_meta("group", _clusters.size() - 1)
		cluster_record["placed"] += 1

		# Add to scene
		get_node("MushroomField").add_child(mushroom)
		mushrooms.append(mushroom)
		_note_light(mushroom)

func create_ambient_lighting() -> void:
	# Add ambient light for the scene
	var ambient = DirectionalLight3D.new()
	ambient.name = "AmbientLight"
	
	# Set light properties
	ambient.light_color = Color(0.9, 0.9, 1.0)
	ambient.light_energy = 0.8
	ambient.shadow_enabled = true
	
	# Position light
	ambient.rotation_degrees = Vector3(-45, 45, 0)
	
	add_child(ambient)
	
	# Add some fog for atmosphere
	add_atmospheric_fog()

func add_atmospheric_fog() -> void:
	# Add fog
	var environment = WorldEnvironment.new()
	environment.name = "Environment"
	
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.07, 0.1)
	
	# Add fog
	env.fog_enabled = true
	#env.fog_color = Color(0.2, 0.25, 0.3)
	env.fog_density = 0.02
	
	# Add ambient light
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.2, 0.25, 0.3)
	env.ambient_light_energy = 0.5
	
	environment.environment = env
	add_child(environment)

func add_ground_details() -> void:
	# Add grass and small plants
	add_grass()
	
	# Add rocks
	add_rocks()
	
	# Add fallen leaves
	add_fallen_leaves()

func add_grass() -> void:
	# Create a MultiMeshInstance for grass
	var grass = MultiMeshInstance3D.new()
	grass.name = "Grass"
	
	# Create grass blade mesh
	var grass_mesh = CylinderMesh.new()
	grass_mesh.top_radius = 0.01
	grass_mesh.bottom_radius = 0.03
	grass_mesh.height = 0.2
	grass_mesh.radial_segments = 3
	
	# Create multimesh
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = grass_mesh
	
	# Set instance count based on meadow size
	var instance_count = int(meadow_size * meadow_size * 10)
	multi_mesh.instance_count = instance_count
	
	# Create grass material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.4, 0.2)
	grass_mesh.material = material
	
	# Set transforms for each instance
	for i in range(instance_count):
		var pos_x = _rf() * meadow_size - meadow_size / 2
		var pos_z = _rf() * meadow_size - meadow_size / 2
		
		# Get ground height
		var ground_height = get_ground_height(pos_x, pos_z)
		
		var transform = Transform3D()
		transform.origin = Vector3(pos_x, ground_height, pos_z)
		
		# Randomize rotation
		transform.basis = Basis(Vector3.UP, _rf() * PI * 2)
		# Randomize scale
		var scale = 0.7 + _rf() * 0.6
		transform.basis = transform.basis.scaled(Vector3(scale, scale + _rf() * 0.5, scale))
		
		multi_mesh.set_instance_transform(i, transform)
	
	grass.multimesh = multi_mesh
	add_child(grass)

func add_rocks() -> void:
	# Add some rocks using MultiMesh (one per mesh type)
	var rock_count = int(meadow_size * 2)
	# Pre-sort by mesh type
	var sphere_rocks: Array[Dictionary] = []
	var box_rocks: Array[Dictionary] = []
	var prism_rocks: Array[Dictionary] = []

	for i in range(rock_count):
		var mesh_type = _ri() % 3
		var size_val = 0.1 + _rf() * 0.3
		var pos_x = _rf() * meadow_size - meadow_size / 2
		var pos_z = _rf() * meadow_size - meadow_size / 2
		var ground_height = get_ground_height(pos_x, pos_z)
		var pos = Vector3(pos_x, ground_height + size_val * 0.35, pos_z)
		var rot = Vector3(_rf() * 30, _rf() * 360, _rf() * 30)
		var entry = {"pos": pos, "rot": rot, "size": size_val}
		match mesh_type:
			0: sphere_rocks.append(entry)
			1: box_rocks.append(entry)
			2: prism_rocks.append(entry)

	var rocks_container = Node3D.new()
	rocks_container.name = "Rocks"

	# Sphere rocks
	if not sphere_rocks.is_empty():
		var mesh = SphereMesh.new()
		mesh.radius = 0.2
		mesh.height = 0.2
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.5, 0.5).darkened(0.15)
		mat.roughness = 0.9
		mesh.material = mat
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = sphere_rocks.size()
		mm.mesh = mesh
		for i in range(sphere_rocks.size()):
			var e = sphere_rocks[i]
			var t = Transform3D()
			t.basis = Basis.from_euler(Vector3(deg_to_rad(e["rot"].x), deg_to_rad(e["rot"].y), deg_to_rad(e["rot"].z)))
			var s = e["size"] / 0.2  # normalize to base size
			t.basis = t.basis.scaled(Vector3(s, s * 0.7, s))
			t.origin = e["pos"]
			mm.set_instance_transform(i, t)
		var mmi = MultiMeshInstance3D.new()
		mmi.name = "SphereRocksMM"
		mmi.multimesh = mm
		rocks_container.add_child(mmi)

	# Box rocks
	if not box_rocks.is_empty():
		var mesh = BoxMesh.new()
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.5, 0.5).darkened(0.15)
		mat.roughness = 0.9
		mesh.material = mat
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = box_rocks.size()
		mm.mesh = mesh
		for i in range(box_rocks.size()):
			var e = box_rocks[i]
			var t = Transform3D()
			t.basis = Basis.from_euler(Vector3(deg_to_rad(e["rot"].x), deg_to_rad(e["rot"].y), deg_to_rad(e["rot"].z)))
			t.basis = t.basis.scaled(Vector3(e["size"], e["size"] * 0.7, e["size"]))
			t.origin = e["pos"]
			mm.set_instance_transform(i, t)
		var mmi = MultiMeshInstance3D.new()
		mmi.name = "BoxRocksMM"
		mmi.multimesh = mm
		rocks_container.add_child(mmi)

	# Prism rocks
	if not prism_rocks.is_empty():
		var mesh = PrismMesh.new()
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.5, 0.5).darkened(0.15)
		mat.roughness = 0.9
		mesh.material = mat
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = prism_rocks.size()
		mm.mesh = mesh
		for i in range(prism_rocks.size()):
			var e = prism_rocks[i]
			var t = Transform3D()
			t.basis = Basis.from_euler(Vector3(deg_to_rad(e["rot"].x), deg_to_rad(e["rot"].y), deg_to_rad(e["rot"].z)))
			t.basis = t.basis.scaled(Vector3(e["size"], e["size"] * 0.7, e["size"]))
			t.origin = e["pos"]
			mm.set_instance_transform(i, t)
		var mmi = MultiMeshInstance3D.new()
		mmi.name = "PrismRocksMM"
		mmi.multimesh = mm
		rocks_container.add_child(mmi)

	add_child(rocks_container)

func add_fallen_leaves() -> void:
	# Add fallen leaves
	var leaf_count = int(meadow_size * meadow_size * 2)
	var leaves = MultiMeshInstance3D.new()
	leaves.name = "FallenLeaves"
	
	# Create leaf mesh
	var leaf_mesh = PrismMesh.new()
	leaf_mesh.size = Vector3(0.1, 0.01, 0.15)
	
	# Create multimesh
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = leaf_mesh
	multi_mesh.instance_count = leaf_count
	
	# Create leaf material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.3, 0.1)
	leaf_mesh.material = material
	
	# Set transforms for each instance
	for i in range(leaf_count):
		var pos_x = _rf() * meadow_size - meadow_size / 2
		var pos_z = _rf() * meadow_size - meadow_size / 2
		
		# Get ground height
		var ground_height = get_ground_height(pos_x, pos_z)
		
		var transform = Transform3D()
		transform.origin = Vector3(pos_x, ground_height + 0.01, pos_z)
		
		# Randomize rotation
		transform.basis = Basis.from_euler(Vector3(
			_rf() * 0.2,
			_rf() * PI * 2,
			_rf() * 0.2
		))

		transform.basis = Basis(Vector3.UP, _rf() * PI * 2)
		multi_mesh.set_instance_transform(i, transform)
	
	leaves.multimesh = multi_mesh
	add_child(leaves)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
	_free_templates()


## The templates are duplicated into the field and never enter the tree themselves; without
## this they outlive the meadow (fifty-one objects leaked at exit, measured 2026-09-12).
func _free_templates() -> void:
	for t in mushroom_types:
		if is_instance_valid(t) and not (t as Node).is_inside_tree():
			(t as Node).free()
	mushroom_types.clear()


## A glowing instance carries an OmniLight; past the cap the light goes dark and the cap keeps
## its emissive glow. No cap on the shipped path (max_glow_lights 0).
func _note_light(mushroom: Node3D) -> void:
	var light: Node = mushroom.get_node_or_null("GlowLight")
	if light == null:
		return
	_glow_instances += 1
	if max_glow_lights > 0 and _lit_lights >= max_glow_lights:
		(light as OmniLight3D).visible = false
	else:
		_lit_lights += 1


## Map tokens. `size` is the bed's side in metres (a whitelisted key), `seed` the population
## seed, `count` and `density` the candidate rule, `stand` the staging. The museum hands the
## config before _ready (the values are stored and _ready builds once with them); the grid
## hands it after, and a built meadow regrows.
func apply_grid_config(config: Dictionary) -> void:
	var regrow_needed := false
	if config.has("size"):
		var ms: float = float(str(config["size"]))
		if ms > 0.5 and not is_equal_approx(ms, meadow_size):
			meadow_size = ms
			regrow_needed = true
	if config.has("count"):
		mushroom_count = maxi(1, int(str(config["count"])))
		regrow_needed = true
	if config.has("density"):
		mushroom_density = clampf(float(str(config["density"])), 0.05, 5.0)
		regrow_needed = true
	if config.has("seed"):
		population_seed = int(str(config["seed"]))
		regrow_needed = true
	if config.has("stand"):
		var sv: String = str(config["stand"]).strip_edges().to_lower()
		stand = "specimen" if sv in ["specimen", "table", "bench", "stand"] else "none"
	if not _built:
		return
	if stand == "specimen":
		_prepare_stand()
		regrow_needed = true
	if regrow_needed:
		regrow()
	_apply_stand()


# ═════════════════════════════════════════════════════════════════════
# THE SPECIMEN TABLE — the staging (stand:specimen): the bed's kerb, the table, its readout,
# the highlight in the bed, the buttons
# ═════════════════════════════════════════════════════════════════════

func _apply_stand() -> void:
	if stand == "specimen":
		if _stand_root == null:
			_build_table()
		_build_kerb()
		_refresh_specimens()
		_refresh_highlight()
		_update_readout()
	else:
		for n in [_stand_root, _kerb, _highlight_mmi, _pins_mmi]:
			if n != null and is_instance_valid(n):
				(n as Node).get_parent().remove_child(n)
				(n as Node).queue_free()
		_stand_root = null
		_kerb = null
		_readout = null
		_panel = null
		_highlight_mmi = null
		_pins_mmi = null
		_specimen_slots.clear()


## The same population again (under the seed) or a new one (on the stream): the ground, the
## templates, the field, the rings and clusters, grass, rocks and leaves are freed and made
## again in the build's order, so a seeded regrow lands every instance where it stood.
func regrow() -> void:
	for nm in ["MushroomField", "Ground", "Grass", "Rocks", "FallenLeaves"]:
		var n: Node = get_node_or_null(nm)
		if n != null:
			remove_child(n)
			n.queue_free()
	mushrooms.clear()
	_free_templates()
	_seed_generators()
	create_ground()
	create_mushroom_templates()
	generate_mushroom_field()
	if add_ground_cover:
		add_ground_details()
	_lift_bed()
	if _stand_root != null:
		_refresh_specimens()
		_refresh_highlight()
		_update_readout()


func new_seed() -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	var next: int = r.randi_range(10000, 99999)
	while next == population_seed:
		next = r.randi_range(10000, 99999)
	population_seed = next
	regrow()


func set_population_seed(value: int) -> void:
	population_seed = value
	regrow()


func set_size_variation(on: bool) -> void:
	size_variation = on
	regrow()


func show_template(index: int) -> void:
	_show_template = posmod(index, maxi(mushroom_types.size(), 1))
	_kind = 0
	_refresh_highlight()
	_update_readout()


func cycle_show() -> void:
	show_template(_show_template + 1)


func set_kind(index: int) -> void:
	_kind = posmod(index, KINDS.size())
	_refresh_highlight()
	_update_readout()


func cycle_kind() -> void:
	set_kind(_kind + 1)


## Four boards around the bed, their top at the ground's highest reach.
func _build_kerb() -> void:
	if _kerb != null and is_instance_valid(_kerb):
		remove_child(_kerb)
		_kerb.queue_free()
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var wood: StandardMaterial3D = HangarKit.finish_body("terminal", Color(0.30, 0.24, 0.18), 0.25)
	_kerb = Node3D.new()
	_kerb.name = "Kerb"
	add_child(_kerb)
	var half: float = meadow_size * 0.5
	var h: float = bed_lift + ground_random_amplitude + 0.04
	var t: float = 0.06
	var boards := [[Vector3(0, h * 0.5, -half - t * 0.5), Vector3(meadow_size + 2 * t, h, t)],
		[Vector3(0, h * 0.5, half + t * 0.5), Vector3(meadow_size + 2 * t, h, t)],
		[Vector3(-half - t * 0.5, h * 0.5, 0), Vector3(t, h, meadow_size)],
		[Vector3(half + t * 0.5, h * 0.5, 0), Vector3(t, h, meadow_size)]]
	for i in range(boards.size()):
		var b: MeshInstance3D = HangarKit.box(boards[i][0], boards[i][1], wood)
		b.name = "Board_%d" % i
		_kerb.add_child(b)


## The table: a body at the bed's +z edge (the map turns the token so that edge faces the
## door) carrying the six type specimens, the readout plate on its front face and the panel
## beside it.
func _build_table() -> void:
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var pal: Dictionary = HangarKit.finish_palette("terminal")
	var shell: StandardMaterial3D = HangarKit.finish_body("terminal", pal["body"], 0.10)
	var steel: StandardMaterial3D = HangarKit.worn_metal((pal["body"] as Color).lightened(0.10))
	_stand_root = Node3D.new()
	_stand_root.name = "SpecimenTable"
	_stand_root.position = Vector3(0.0, 0.0, meadow_size * 0.5 + TABLE_GAP + TABLE_D * 0.5)
	add_child(_stand_root)
	var body := StaticBody3D.new()
	body.name = "Body"
	_stand_root.add_child(body)
	var top: MeshInstance3D = HangarKit.box(Vector3(0, TABLE_H - 0.02, 0), Vector3(TABLE_W, 0.04, TABLE_D), steel)
	top.name = "Top"
	body.add_child(top)
	var post: MeshInstance3D = HangarKit.box(Vector3(0, (TABLE_H - 0.04) * 0.5, 0), Vector3(TABLE_W * 0.94, TABLE_H - 0.04, TABLE_D * 0.7), shell)
	post.name = "Post"
	body.add_child(post)
	var col := CollisionShape3D.new()
	col.name = "Collider"
	var shape := BoxShape3D.new()
	shape.size = Vector3(TABLE_W, TABLE_H, TABLE_D)
	col.shape = shape
	col.position = Vector3(0, TABLE_H * 0.5, 0)
	body.add_child(col)
	var face: float = TABLE_D * 0.5
	var sign: MeshInstance3D = HangarKit.stencil("SPECIMENS · ONE POPULATION", Vector2(0.50, 0.026), (pal["accent"] as Color).lightened(0.35))
	if sign:
		sign.position = Vector3(-0.30, 0.60, face + 0.004)
		_stand_root.add_child(sign)
	# six discs for the type specimens, along the top
	var slots := Node3D.new()
	slots.name = "Specimens"
	_stand_root.add_child(slots)
	for k in range(6):
		var disc: MeshInstance3D = HangarKit.box(Vector3(-0.55 + 0.22 * k, TABLE_H + 0.008, -0.04), Vector3(0.18, 0.016, 0.18), steel)
		disc.name = "Disc_%d" % k
		slots.add_child(disc)
		var tag := Label3D.new()
		tag.name = "Tag_%d" % k
		tag.text = str(k)
		tag.pixel_size = 0.0012
		tag.font_size = 14
		tag.modulate = Color(0.86, 0.94, 1.0)
		tag.position = Vector3(-0.55 + 0.22 * k, TABLE_H + 0.02, 0.12)
		tag.rotation_degrees = Vector3(-90, 0, 0)
		slots.add_child(tag)
	# the readout plate, on the front face, leaning back so a standing eye reads it
	var plate_root := Node3D.new()
	plate_root.name = "Readout"
	plate_root.set_meta("em_local_instrument", true)
	plate_root.position = Vector3(-0.30, TABLE_H - 0.13, face + 0.012)
	plate_root.rotation_degrees = Vector3(-12, 0, 0)
	_stand_root.add_child(plate_root)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.8
	var plate: MeshInstance3D = HangarKit.box(Vector3.ZERO, Vector3(0.78, 0.15, 0.014), dark)
	plate.name = "Plate"
	plate_root.add_child(plate)
	_readout = Label3D.new()
	_readout.name = "Text"
	_readout.pixel_size = 0.00095
	_readout.font_size = 15
	_readout.outline_size = 0
	_readout.line_spacing = 0.5
	_readout.modulate = Color(0.86, 0.94, 1.0)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_readout.position = Vector3(-0.37, 0.066, 0.010)
	plate_root.add_child(_readout)
	# the panel: SHOW · KIND · SIZE / REGROW · NEW SEED, on the front face beside the plate
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl != null:
		_panel = RackTpl.create_panel("", [
			[{"type": "button", "label": "SHOW"}, {"type": "button", "label": "KIND"}, {"type": "button", "label": "SIZE"}],
			[{"type": "button", "label": "REGROW"}, {"type": "button", "label": "NEW SEED"}],
		], true)
		_panel.name = "Panel"
		_panel.set_meta("em_local_instrument", true)
		_panel.position = Vector3(0.47, TABLE_H - 0.20, face + 0.076)
		_panel.rotation_degrees = Vector3(-32, 0, 0)
		_stand_root.add_child(_panel)
		var actions := {"Btn_0": func(): cycle_show(), "Btn_1": func(): cycle_kind(), "Btn_2": func(): set_size_variation(not size_variation), "Btn_3": func(): regrow(), "Btn_4": func(): new_seed()}
		for btn_name in actions.keys():
			var btn: Node = _panel.find_child(btn_name, true, false)
			if btn == null:
				continue
			var area: Node = btn.get_node_or_null("InteractableAreaButton")
			if area != null and area.has_signal("button_pressed"):
				var action: Callable = actions[btn_name]
				area.button_pressed.connect(func(_b): action.call())
	# the highlight: a ring outline wider than a cap around each marked instance, on the
	# ground, and a pin above it (a flat disc hides under the cap and in the slope)
	var hm := StandardMaterial3D.new()
	hm.vertex_color_use_as_albedo = true
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ring := TorusMesh.new()
	ring.inner_radius = 0.23
	ring.outer_radius = 0.28
	ring.rings = 24
	ring.ring_segments = 6
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = ring
	mm.instance_count = 0
	_highlight_mmi = MultiMeshInstance3D.new()
	_highlight_mmi.name = "Highlight"
	_highlight_mmi.multimesh = mm
	_highlight_mmi.material_override = hm
	add_child(_highlight_mmi)
	var pin := SphereMesh.new()
	pin.radius = 0.045
	pin.height = 0.09
	pin.radial_segments = 12
	pin.rings = 6
	var pm := MultiMesh.new()
	pm.transform_format = MultiMesh.TRANSFORM_3D
	pm.use_colors = true
	pm.mesh = pin
	pm.instance_count = 0
	_pins_mmi = MultiMeshInstance3D.new()
	_pins_mmi.name = "Pins"
	_pins_mmi.multimesh = pm
	_pins_mmi.material_override = hm
	add_child(_pins_mmi)


## The six templates duplicated onto their discs at scale 0.8 (type specimens), refreshed after
## every regrow (the templates are made again with the population).
func _refresh_specimens() -> void:
	var slots: Node3D = _stand_root.get_node_or_null("Specimens") if _stand_root != null else null
	if slots == null:
		return
	for old in _specimen_slots:
		if is_instance_valid(old):
			slots.remove_child(old)
			(old as Node).queue_free()
	_specimen_slots.clear()
	for k in range(mini(6, mushroom_types.size())):
		var spec: Node3D = (mushroom_types[k] as Node3D).duplicate()
		spec.name = "Specimen_%d" % k
		spec.position = Vector3(-0.55 + 0.22 * k, TABLE_H + 0.016, -0.04)
		spec.scale = Vector3(0.8, 0.8, 0.8)
		var light: Node = spec.get_node_or_null("GlowLight")
		if light != null:
			(light as OmniLight3D).visible = false
		slots.add_child(spec)
		_specimen_slots.append(spec)


## What is ringed in the bed: every instance of the shown template, or every scattered
## instance, every ring member, every cluster member, or every rejected candidate.
func _refresh_highlight() -> void:
	if _highlight_mmi == null:
		return
	var pts: Array = []
	var col: Color = Color(1.0, 0.72, 0.2)
	match KINDS[_kind]:
		"template":
			for m in mushrooms:
				if is_instance_valid(m) and int((m as Node).get_meta("template", -1)) == _show_template:
					pts.append((m as Node3D).position)
		"scattered":
			col = Color(0.55, 0.9, 1.0)
			for m in mushrooms:
				if is_instance_valid(m) and str((m as Node).get_meta("kind", "")) == "scattered":
					pts.append((m as Node3D).position)
		"rings":
			col = Color(0.4, 1.0, 0.5)
			for m in mushrooms:
				if is_instance_valid(m) and str((m as Node).get_meta("kind", "")) == "ring":
					pts.append((m as Node3D).position)
		"clusters":
			col = Color(0.75, 0.55, 1.0)
			for m in mushrooms:
				if is_instance_valid(m) and str((m as Node).get_meta("kind", "")) == "cluster":
					pts.append((m as Node3D).position)
		"rejected":
			col = Color(0.5, 0.5, 0.55)
			for p in _rejected:
				pts.append(p)
	var pin_h: float = 0.35 if KINDS[_kind] == "rejected" else 0.75
	var mm: MultiMesh = _highlight_mmi.multimesh
	var pm: MultiMesh = _pins_mmi.multimesh if _pins_mmi != null else null
	mm.instance_count = pts.size()
	if pm != null:
		pm.instance_count = pts.size()
	for i in range(pts.size()):
		var p: Vector3 = pts[i]
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(p.x, p.y + bed_lift + 0.04, p.z)))
		mm.set_instance_color(i, col)
		if pm != null:
			pm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(p.x, p.y + bed_lift + pin_h, p.z)))
			pm.set_instance_color(i, col)


func highlighted_count() -> int:
	return _highlight_mmi.multimesh.instance_count if _highlight_mmi != null else 0


func readout_lines() -> Array[String]:
	var scattered: int = 0
	var ring_placed: int = 0
	var cluster_placed: int = 0
	var shown: int = 0
	for m in mushrooms:
		if not is_instance_valid(m):
			continue
		var kind: String = str((m as Node).get_meta("kind", ""))
		if kind == "scattered": scattered += 1
		elif kind == "ring": ring_placed += 1
		elif kind == "cluster": cluster_placed += 1
		if int((m as Node).get_meta("template", -1)) == _show_template:
			shown += 1
	var seed_line: String = "seed %d · REGROW grows it again" % population_seed if population_seed >= 0 else "seed: the global stream · REGROW: new"
	var show_line: String
	match KINDS[_kind]:
		"template":
			show_line = "SHOW template %d · %d instances ringed" % [_show_template, shown]
		"scattered":
			show_line = "KIND scattered · %d ringed" % scattered
		"rings":
			show_line = "KIND rings · %d members ringed" % ring_placed
		"clusters":
			show_line = "KIND clusters · %d members ringed" % cluster_placed
		_:
			show_line = "KIND rejected · %d candidates marked" % _rejected.size()
	var size_line: String = "size 0.7–1.3 · ring 0.8–1.2 · cluster 0.5–1.2" if size_variation else "SIZE off · every mushroom at 1 · same seed"
	return [seed_line,
		"candidates %d · accepted %d · rejected %d" % [_candidates_requested, scattered, _rejected.size()],
		"rings %d (%d) · clusters %d (%d) · templates %d" % [_rings.size(), ring_placed, _clusters.size(), cluster_placed, mushroom_types.size()],
		show_line, size_line,
		"glow %d · lit %d of %d · mushrooms %d" % [_glow_instances, _lit_lights, max_glow_lights if max_glow_lights > 0 else _glow_instances, mushrooms.size()]]


func _update_readout() -> void:
	if _readout == null:
		return
	_readout.text = "\n".join(readout_lines())


## The population, instance by instance, for a probe: template, kind, group, transform.
func instances() -> Array:
	var out: Array = []
	for m in mushrooms:
		if not is_instance_valid(m):
			continue
		var n: Node3D = m
		out.append({"template": int(n.get_meta("template", -1)), "kind": str(n.get_meta("kind", "")), "group": int(n.get_meta("group", -1)),
			"x": n.position.x, "y": n.position.y, "z": n.position.z, "yaw": n.rotation_degrees.y, "scale": n.scale.x})
	return out


func ground_signature() -> Dictionary:
	var h: int = 0
	var lo: float = 1e9
	var hi: float = -1e9
	for v in ground_height_grid:
		h = hash([h, snappedf(v, 0.0001)])
		lo = minf(lo, v)
		hi = maxf(hi, v)
	return {"cells": ground_height_grid.size(), "hash": h, "min": lo, "max": hi}


func get_specimen_state() -> Dictionary:
	var lines: Array[String] = readout_lines()
	return {"stand": stand, "seed": population_seed, "replay": population_seed >= 0, "size_variation": size_variation,
		"candidates": _candidates_requested, "rejected": _rejected.size(), "rings": _rings.duplicate(true), "clusters": _clusters.duplicate(true),
		"templates": mushroom_types.size(), "show_template": _show_template, "kind": KINDS[_kind], "highlighted": highlighted_count(),
		"glow_instances": _glow_instances, "lit_lights": _lit_lights, "max_glow_lights": max_glow_lights, "instances": instances(),
		"ground": ground_signature(), "meadow_size": meadow_size, "bed_lift": bed_lift, "lines": lines}
