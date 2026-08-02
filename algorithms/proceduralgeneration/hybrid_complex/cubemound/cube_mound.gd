# cube_mound.gd - Drop cubes and generate mesh from pile
extends Node3D

# @identity
# essence: drop(N cubes) -> wait(settle) -> voxelize(positions) -> surface_mesh — physics simulation crystallized into static geometry
# desire: to watch cubes rain down, pile up, and then see the pile freeze into a sculptural mound you can walk on
# critical_parameter: release — the shape the cubes were being HELD in at the moment of letting go
#   (cylinder, ring, sheet, chute, rift). num_cubes and spawn_radius set how much and how wide;
#   release sets what the heap will BE, and it is the only one a still can hold.
# triggers: start_generation drops cubes; settling detection (all RigidBody3D.sleeping) triggers mesh generation; Space key restarts
# emerges: the voxelized mesh smooths over individual cube positions, creating an organic-looking surface from discrete physics objects
# needs: physics simulation [has]; voxel-to-mesh conversion [has]; trimesh collision [has]; VR cube dropping [missing]; real-time voxelization [missing]
# relationships: paired with dome and layered_membrane in PG_Sculpted_Forms; contrasts accumulation (bottom-up) with subdivision (top-down)
# truth: a mound is not designed — it is what gravity does to a collection of objects when you stop
#   holding them up. Gravity is the same everywhere, so the shape you were holding them in is the
#   whole of the design, and this artifact had it hardcoded and unnamed until now.

@export var num_cubes: int = 20
@export var cube_size: float = 1.0
@export var spawn_height: float = 10.0
@export var spawn_radius: float = 3.0
@export var settle_time: float = 3.0
@export var voxel_size: float = 0.5
@export var generate_on_start: bool = true

# ── DNA ───────────────────────────────────────────────────────────────────────
# THE AXIS — the shape you were HOLDING the cubes in at the moment you let go.
#
# The identity's truth is that "a mound is not designed — it is what gravity does to a
# collection of objects when you stop holding them up". That sentence hides one decision
# it does not admit to: gravity is the same everywhere, so the only thing left that can
# decide the landform is the geometry of the release. This artifact has always had a
# release geometry — a disc of radius spawn_radius, two metres of height jitter, hardcoded
# into drop_cubes — and has never called it a choice. It is the choice. So it becomes the
# axis, and the family argues that accretion is not designed but its INTAKE is.
#
#   cylinder  the legacy lineage, byte for byte — a filled disc r <= spawn_radius, 2 m of
#             height jitter. Reads as a squarish cloud that lands as one broad heap.
#   ring      the same disc with its middle taken out (r in 0.8..1.0 of spawn_radius). An
#             annulus of cubes; what lands is a crater with a bare centre.
#   sheet     a wide flat square raft, 3 x spawn_radius across and 0.4 m thick. Falls as a
#             single storey and spreads into a plateau rather than a peak.
#   chute     one narrow throat, 0.35 x spawn_radius wide and six metres tall. Everything
#             arrives through the same hole, so what lands is a cone from a point source.
#   rift      a straight line four spawn_radii long and a metre deep. A wall of cubes; what
#             lands is a ridge, not a mound.
#
# VISIBLE IN A STILL, AND THAT IS WHY IT IS THIS AND NOT THE MOUND. The mound is a
# PROCESS — drop, settle, voxelise — that needs seconds of physics, and a capture at ~1.2 s
# catches the cubes still in the air. What a still CAN hold is the falling cloud, and the
# cloud is the release geometry in mid-flight. The same axis is what the finished mound is
# made of, so the sweep and the room agree about what it means.
#
# NOT TOUCHED: gravity, the settle detection, the voxel grid, the surface extraction. The
# mathematics is the curriculum. This changes only where the matter enters.
@export_enum("cylinder", "ring", "sheet", "chute", "rift") var release: String = "cylinder"
## The allow-list a map token is checked against — the same five words, same spelling,
## same order as the enum above.
const RELEASES: PackedStringArray = ["cylinder", "ring", "sheet", "chute", "rift"]

## Seed for the spawn draws. -1 keeps the legacy behaviour (Godot randomises the global
## stream at startup, so every drop is a different cloud); any value >= 0 pins it so the
## same cloud comes back. Without this a sweep of `release` compares five different random
## clouds and reports the difference between draws as the bite of the axis.
@export var release_seed: int = -1

var cubes: Array = []
var state: String = "idle"  # idle, dropping, settling, generating, done
var timer: float = 0.0
var generated_mesh: MeshInstance3D = null

@onready var ground = $Ground

func _ready() -> void:
	if generate_on_start:
		start_generation()

func start_generation() -> void:
	if state != "idle" and state != "done":
		return
	
	clear_cubes()
	clear_generated_mesh()
	
	print("Dropping %d cubes..." % num_cubes)
	drop_cubes()
	state = "dropping"
	timer = 0.0

func drop_cubes() -> void:
	# A pinned seed makes the whole drop reproducible. -1 leaves the global stream exactly
	# as it was, so the default build draws the same numbers it always did.
	if release_seed >= 0:
		seed(release_seed)
	for i in range(num_cubes):
		var cube = RigidBody3D.new()

		# Random spawn position in cylinder above ground
		var angle = randf() * TAU
		var radius = randf() * spawn_radius
		var spawn_pos = Vector3(
			cos(angle) * radius,
			spawn_height + randf() * 2.0,
			sin(angle) * radius
		)
		# ── AXIS: release ── THE THREE DRAWS ABOVE HAPPEN FIRST AND UNCONDITIONALLY, for
		# every value of the axis. _release_position re-reads those same three numbers as
		# uniform deviates and re-shapes them; it never draws. That is what keeps the RNG
		# stream identical across the family — a randf() inside a branch would shift every
		# subsequent cube's colour and rotation and make two "identical" seeds diverge.
		if release != "cylinder":
			spawn_pos = _release_position(angle, radius, spawn_pos.y)
		cube.position = spawn_pos
		
		# Random rotation
		cube.rotation = Vector3(
			randf() * TAU,
			randf() * TAU,
			randf() * TAU
		)
		
		# Add collision shape
		var collision = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3.ONE * cube_size
		collision.shape = box_shape
		cube.add_child(collision)
		
		# Add visual mesh
		var mesh_instance = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3.ONE * cube_size
		mesh_instance.mesh = box_mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(randf(), randf(), randf())
		mesh_instance.material_override = material
		cube.add_child(mesh_instance)
		
		add_child(cube)
		cubes.append(cube)
	
	print("Cubes dropped! Waiting for settlement...")

## Re-shape one already-drawn spawn into the geometry `release` names.
##
## It takes the three numbers drop_cubes has ALREADY drawn and reads them back as the
## uniform deviates they are — angle as v in 0..1, radius as u in 0..1, the height jitter
## as t in 0..1 — so every value of the axis consumes exactly the same three draws in
## exactly the same order. `cylinder` never gets here; it is the untouched legacy path.
func _release_position(angle: float, radius: float, base_y: float) -> Vector3:
	var span: float = maxf(spawn_radius, 0.0001)
	var u: float = clampf(radius / span, 0.0, 1.0)
	var v: float = clampf(angle / TAU, 0.0, 1.0)
	var t: float = clampf((base_y - spawn_height) * 0.5, 0.0, 1.0)

	match release:
		"ring":
			# The disc with its middle taken out — an annulus in the outer fifth.
			var r: float = spawn_radius * (0.8 + 0.2 * u)
			return Vector3(cos(angle) * r, base_y, sin(angle) * r)
		"sheet":
			# A broad flat raft: a square three spawn_radii across, 0.4 m thick.
			var half: float = spawn_radius * 1.5
			return Vector3(half * (2.0 * u - 1.0),
				spawn_height + t * 0.4,
				half * (2.0 * v - 1.0))
		"chute":
			# One narrow throat, tall instead of wide. sqrt(u) keeps the cross-section
			# evenly filled rather than crowding the axis.
			var rc: float = spawn_radius * 0.35 * sqrt(u)
			return Vector3(cos(angle) * rc, spawn_height + t * 6.0, sin(angle) * rc)
		"rift":
			# A line, not a disc: four spawn_radii long and a metre deep.
			return Vector3(spawn_radius * 2.0 * (2.0 * v - 1.0), base_y, u - 0.5)
	return Vector3(cos(angle) * radius, base_y, sin(angle) * radius)

func _process(delta: float) -> void:
	if state == "dropping":
		timer += delta
		# Wait a moment for cubes to start falling
		if timer > 0.5:
			state = "settling"
			timer = 0.0
	
	elif state == "settling":
		timer += delta
		
		# Check if all cubes are sleeping (settled)
		var all_settled = true
		for cube in cubes:
			if cube is RigidBody3D and not cube.sleeping:
				all_settled = false
				break
		
		# Force generation after settle_time regardless
		if timer > settle_time or all_settled:
			print("Cubes settled! Generating mesh...")
			state = "generating"
			# Wait a moment for physics to fully settle
			await get_tree().create_timer(0.5).timeout
			generate_mesh_from_cubes()
			state = "done"
			print("Mesh generation complete!")

func generate_mesh_from_cubes() -> void:
	# Get all cube positions (using global position for accuracy)
	var positions = []
	for cube in cubes:
		if cube is RigidBody3D:
			# Store global position for accurate positioning
			positions.append(cube.global_position)
	
	if positions.is_empty():
		print("No cubes to generate mesh from!")
		return
	
	# Find bounds
	var min_bounds = positions[0]
	var max_bounds = positions[0]
	
	for pos in positions:
		min_bounds.x = min(min_bounds.x, pos.x)
		min_bounds.y = min(min_bounds.y, pos.y)
		min_bounds.z = min(min_bounds.z, pos.z)
		max_bounds.x = max(max_bounds.x, pos.x)
		max_bounds.y = max(max_bounds.y, pos.y)
		max_bounds.z = max(max_bounds.z, pos.z)
	
	# Expand bounds by cube size
	min_bounds -= Vector3.ONE * cube_size
	max_bounds += Vector3.ONE * cube_size
	
	# Create voxel grid
	var grid_size = ((max_bounds - min_bounds) / voxel_size).ceil()
	var voxel_grid = {}
	
	# Mark voxels occupied by cubes
	for pos in positions:
		var voxel_pos = ((pos - min_bounds) / voxel_size).floor()
		
		# Mark cube volume as occupied (cube_size in voxels)
		var half_extent = int(ceil(cube_size / voxel_size))
		for x in range(-half_extent, half_extent + 1):
			for y in range(-half_extent, half_extent + 1):
				for z in range(-half_extent, half_extent + 1):
					var check_pos = voxel_pos + Vector3(x, y, z)
					var key = "%d,%d,%d" % [check_pos.x, check_pos.y, check_pos.z]
					voxel_grid[key] = true
	
	# Generate mesh from surface voxels
	var surface_mesh = create_mesh_from_voxels(voxel_grid, min_bounds, grid_size)
	
	# Create mesh instance
	generated_mesh = MeshInstance3D.new()
	generated_mesh.mesh = surface_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.4)
	material.roughness = 0.8
	material.metallic = 0.0
	generated_mesh.material_override = material
	
	add_child(generated_mesh)
	
	# Remove physics from original cubes (disable colliders and freeze them)
	for cube in cubes:
		if cube is RigidBody3D:
			# Disable collision detection
			cube.collision_layer = 0
			cube.collision_mask = 0
			# Freeze the cube to prevent further physics updates
			cube.freeze = true
			# Optionally hide them
			cube.visible = false
	
	# Wait a frame to ensure mesh is fully added to scene tree
	await get_tree().process_frame
	
	# Create collider from generated mesh so the player can walk on the mound
	var static_body := StaticBody3D.new()
	static_body.name = "MoundCollider"
	var collider := CollisionShape3D.new()
	var tri_shape := surface_mesh.create_trimesh_shape()
	if tri_shape:
		collider.shape = tri_shape
		static_body.add_child(collider)
		add_child(static_body)
		print("Collider created with %d triangles" % [tri_shape.get_faces().size() / 3])
	else:
		print("WARNING: Failed to create trimesh shape for collider")

func create_mesh_from_voxels(voxel_grid: Dictionary, min_bounds: Vector3, grid_size: Vector3) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# For each occupied voxel, check neighbors and add faces for exposed sides
	for key in voxel_grid.keys():
		var parts = key.split(",")
		var x = int(parts[0])
		var y = int(parts[1])
		var z = int(parts[2])
		var pos = Vector3(x, y, z)
		
		# Check each face direction
		var directions = [
			Vector3(1, 0, 0),   # Right
			Vector3(-1, 0, 0),  # Left
			Vector3(0, 1, 0),   # Up
			Vector3(0, -1, 0),  # Down
			Vector3(0, 0, 1),   # Forward
			Vector3(0, 0, -1)   # Back
		]
		
		for dir in directions:
			var neighbor_pos = pos + dir
			var neighbor_key = "%d,%d,%d" % [neighbor_pos.x, neighbor_pos.y, neighbor_pos.z]
			
			# If neighbor is not occupied, this face is exposed
			if not voxel_grid.has(neighbor_key):
				add_voxel_face(st, pos, dir, min_bounds)
	
	st.generate_normals()
	return st.commit()

func add_voxel_face(st: SurfaceTool, voxel_pos: Vector3, normal: Vector3, min_bounds: Vector3) -> void:
	# Convert voxel position to world position
	var world_pos = min_bounds + voxel_pos * voxel_size
	var half_size = voxel_size * 0.5
	
	# Define vertices based on face normal
	var vertices = []
	
	if normal == Vector3(1, 0, 0):  # Right face (+X)
		vertices = [
			world_pos + Vector3(half_size, -half_size, -half_size),
			world_pos + Vector3(half_size, -half_size, half_size),
			world_pos + Vector3(half_size, half_size, half_size),
			world_pos + Vector3(half_size, half_size, -half_size)
		]
	elif normal == Vector3(-1, 0, 0):  # Left face (-X)
		vertices = [
			world_pos + Vector3(-half_size, -half_size, half_size),
			world_pos + Vector3(-half_size, -half_size, -half_size),
			world_pos + Vector3(-half_size, half_size, -half_size),
			world_pos + Vector3(-half_size, half_size, half_size)
		]
	elif normal == Vector3(0, 1, 0):  # Top face (+Y)
		vertices = [
			world_pos + Vector3(-half_size, half_size, -half_size),
			world_pos + Vector3(half_size, half_size, -half_size),
			world_pos + Vector3(half_size, half_size, half_size),
			world_pos + Vector3(-half_size, half_size, half_size)
		]
	elif normal == Vector3(0, -1, 0):  # Bottom face (-Y)
		vertices = [
			world_pos + Vector3(-half_size, -half_size, half_size),
			world_pos + Vector3(half_size, -half_size, half_size),
			world_pos + Vector3(half_size, -half_size, -half_size),
			world_pos + Vector3(-half_size, -half_size, -half_size)
		]
	elif normal == Vector3(0, 0, 1):  # Front face (+Z)
		vertices = [
			world_pos + Vector3(-half_size, -half_size, half_size),
			world_pos + Vector3(-half_size, half_size, half_size),
			world_pos + Vector3(half_size, half_size, half_size),
			world_pos + Vector3(half_size, -half_size, half_size)
		]
	elif normal == Vector3(0, 0, -1):  # Back face (-Z)
		vertices = [
			world_pos + Vector3(half_size, -half_size, -half_size),
			world_pos + Vector3(half_size, half_size, -half_size),
			world_pos + Vector3(-half_size, half_size, -half_size),
			world_pos + Vector3(-half_size, -half_size, -half_size)
		]
	
	# Add two triangles for the quad
	st.set_normal(normal)
	st.add_vertex(vertices[0])
	st.add_vertex(vertices[1])
	st.add_vertex(vertices[2])
	
	st.add_vertex(vertices[0])
	st.add_vertex(vertices[2])
	st.add_vertex(vertices[3])

func clear_cubes() -> void:
	for cube in cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	cubes.clear()

func clear_generated_mesh() -> void:
	if generated_mesh and is_instance_valid(generated_mesh):
		generated_mesh.queue_free()
	generated_mesh = null

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			start_generation()
		elif event.keycode == KEY_T:
			# Toggle cube visibility
			if not cubes.is_empty():
				var visible = !cubes[0].visible
				for cube in cubes:
					cube.visible = visible
		elif event.keycode == KEY_R:
			# Regenerate with different random positions
			get_tree().reload_current_scene()

func _exit_tree() -> void:
	clear_cubes()
	clear_generated_mesh()

## A map may set #release: and #release_seed:. GUARDED — a config carrying neither key
## returns before touching anything, so a placement that only wanted a rotation does not
## re-drop two hundred rigid bodies.
func apply_grid_config(config: Dictionary) -> void:
	var before_release: String = release
	var before_seed: int = release_seed
	if config.has("release"):
		release = _pick_axis(str(config["release"]), RELEASES, release)
	if config.has("release_seed"):
		release_seed = int(config["release_seed"])
	if release == before_release and release_seed == before_seed:
		return
	state = "idle"
	start_generation()

## An unreadable token resolves to the value already in place rather than to silence.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback
