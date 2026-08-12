# FifteenCasesController.gd
# Demonstrates the 15 unique surface cases of the Marching Cubes algorithm
# Each case represents a fundamental surface topology that can occur

extends Node3D

# --- DNA (stage 2, promoted 2026-08-12) -------------------------------------
# THE SEQUENCE'S TRUTH LINE is "define a field, extract a surface — the boundary
# between inside and outside becomes geometry." This artifact is the only object in
# the sequence that shows the extractor's LOOKUP TABLE itself: 256 corner
# configurations folded by symmetry to fifteen, laid out as a 3 x 5 grid of frozen
# cells. Nothing here moves. Everything here is a decision already taken, and both
# axes ask which part of that decision the demo is willing to put on the table.
#
# workings — HOW MUCH OF THE LOOKUP TABLE'S OPERATION IS DRAWN. The word, and its
#   four rungs, are csg_difference_demo's, whose registry note reads "workings is
#   the axis a demonstration wants and an artwork does not: how much of the
#   operation it is willing to show." This is that same question asked of the same
#   kind of object — a demonstration, not a work — and all four rungs are
#   answerable here in full, which is the test implicit_surface_modeling applied
#   when it REFUSED sierpinski_pyramid's `packing`.
#     expression  SHIPPED. The whole apparatus: fifteen extracted sheets, fifteen
#                 wireframe cages, 120 red/blue corner samples and fifteen billboard
#                 labels each ending "Config: %d" — the lookup-table entry itself.
#     outcome     the fifteen sheets ALONE. Finished geometry with no account of
#                 where it came from: no cage, no samples, no configuration number.
#     operands    cage and corner samples with NO sheet. The field before the
#                 decision — which is exactly and only what marching cubes consumes.
#                 An inverse silhouette of `outcome`.
#     trace       expression plus a marker on every cage edge whose two ends
#                 disagree, sitting at the interpolated crossing. Those points are
#                 what the extractor computes before the table tells it how to join
#                 them; the picture normally shows only the joining.
#
# margin — HOW FAR THE CORNER SAMPLES SIT FROM THE LINE, WITH THE CLASSIFICATION
#   HELD FIXED. The demo hardcoded 0.3 for "outside" and 0.7 for "inside" against
#   MarchingCubesGenerator's threshold of 0.5, fifteen times over. That pair is
#   SYMMETRIC about the threshold, so every interpolated vertex lands on the exact
#   edge midpoint — the diagram-book picture, and an accident of two literals rather
#   than a property of the algorithm. Slide the pair while keeping its span at 0.4
#   and the fifteen cases stay the same fifteen cases: same config bytes, same table
#   entries, same topology, same red and blue beads in the same places — while every
#   sheet slides across its cell. That is the sequence's truth line at its sharpest.
#   The table decides what the surface IS. The numbers decide where it SITS. Only
#   one of those is in the lookup table.
#     even       SHIPPED (0.30, 0.70). t = 0.50 from the inside corner: midpoints.
#     starved    (0.14, 0.54). t = 0.10 — the inside corners barely made it and the
#                sheets hug them, so the solid is slivers.
#     swollen    (0.44, 0.84). t = 0.85 — the sheets stand off toward the outside
#                corners and the solid nearly fills its cell.
#     brimming   (0.48, 0.88). t = 0.95 — the limit case.
#   BOTH numbers of every pair must stay strictly off 0.5. march_cube_fixed's sign
#   test is `density < threshold`, so an outside value of exactly 0.50 flips into
#   the inside class, the configuration collapses to 0 or 255, and the cell renders
#   NOTHING.
#
# WHAT IS DECLINED, by name. `animate_threshold` — the A key, and the only thing
# _process has ever done — is refused. It is a time-domain export twice over: it
# oscillates on sin(animation_time), and what it writes is material.emission_energy,
# a brightness ramp. A still photographs one arbitrary phase of it, so a sweep over
# it would measure the shutter. Worse, its name promises this sequence's central
# question and delivers a glow — it does not move a threshold at all, it modulates
# emission on meshes that were already built. `margin` is the honest version of what
# that export pretends to be, and the export stays exactly as it shipped (false).
# Also refused: case_spacing, case_scale, zoom_speed / min_zoom / max_zoom — layout
# and camera magnitudes that self-cancel under an AABB-fitted capture camera.
const WORKINGS: PackedStringArray = ["expression", "outcome", "operands", "trace"]
const MARGINS: PackedStringArray = ["even", "starved", "swollen", "brimming"]

## (outside, inside) sample pairs. The span is 0.4 in every rung, so the fifteen
## configurations are byte-identical across the axis and only the crossing moves.
## `even` is the pair the fifteen dictionary literals below already contain.
const MARGIN_PAIRS: Dictionary = {
	"even": [0.30, 0.70],
	"starved": [0.14, 0.54],
	"swollen": [0.44, 0.84],
	"brimming": [0.48, 0.88],
}

## MarchingCubesGenerator.threshold, which generate_case_mesh has always set to 0.5.
const THRESHOLD: float = 0.5
## The value create_voxel_chunk_from_case has always filled the chunk with, and the
## "outside" number in all fifteen literals. Named so `even` can be a short-circuit
## back to it rather than a recomputation that happens to land on it.
const SHIPPED_OUTSIDE: float = 0.3
## The grid the fifteen cells have always been laid out on. Was `rows`/`cols` locals
## in generate_fifteen_cases and bare 5 / 4 / 2 literals in create_labels; the
## arithmetic below is unchanged.
const GRID_COLS: int = 5
const GRID_ROWS: int = 3
## Corner-sample bead radius, and the artifact's true minimum corner.
const CORNER_RADIUS: float = 0.08
## workings = trace. Deliberately LARGER than a corner bead: the crossings are the
## thing the rung exists to point at, and they sit on the sheet boundary where a
## smaller mark would be swallowed by the sheet itself.
const CROSSING_RADIUS: float = 0.1
const CROSSING_COLOR: Color = Color(1.0, 0.78, 0.25)

## Which cube corners each of the twelve edges joins. Hoisted out of
## create_wireframe_cube so the crossing markers mark the SAME twelve edges the
## cage draws, in the same order, rather than a second hand-typed copy of them.
const EDGE_CONNECTIONS: Array = [
	[0, 1], [1, 2], [2, 3], [3, 0],  # Bottom face
	[4, 5], [5, 6], [6, 7], [7, 4],  # Top face
	[0, 4], [1, 5], [2, 6], [3, 7]   # Vertical edges
]

# The 15 unique surface cases with their representative configurations
# Using 0.3 for "outside" and 0.7 for "inside" to ensure proper threshold crossing at 0.5
var fifteen_cases = [
	{
		"name": "Case 0: Empty",
		"description": "All vertices outside surface",
		"config": 0,  # 00000000 - no vertices inside
		"densities": [0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 1: Single Corner",
		"description": "One vertex inside surface",
		"config": 1,  # 00000001 - vertex 0 inside
		"densities": [0.7, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 2: Adjacent Corners",
		"description": "Two adjacent vertices inside",
		"config": 3,  # 00000011 - vertices 0,1 inside
		"densities": [0.7, 0.7, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 3: Triangle Corner",
		"description": "Three vertices forming triangle",
		"config": 7,  # 00000111 - vertices 0,1,2 inside
		"densities": [0.7, 0.7, 0.7, 0.3, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 4: Diagonal Corners",
		"description": "Two opposite corners",
		"config": 9,  # 00001001 - vertices 0,3 inside (diagonal)
		"densities": [0.7, 0.3, 0.3, 0.7, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 5: L-Shape",
		"description": "Four vertices in L-shape",
		"config": 15, # 00001111 - bottom face inside
		"densities": [0.7, 0.7, 0.7, 0.7, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 6: Wedge",
		"description": "Triangular wedge shape",
		"config": 23, # 00010111 - 5 vertices inside
		"densities": [0.7, 0.7, 0.7, 0.3, 0.7, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 7: Tunnel",
		"description": "Tube/tunnel through cube",
		"config": 51, # 00110011 - creates tunnel
		"densities": [0.7, 0.7, 0.3, 0.3, 0.7, 0.7, 0.3, 0.3]
	},
	{
		"name": "Case 8: Saddle",
		"description": "Saddle point configuration",
		"config": 85, # 01010101 - alternating pattern
		"densities": [0.7, 0.3, 0.7, 0.3, 0.7, 0.3, 0.7, 0.3]
	},
	{
		"name": "Case 9: Complex Saddle",
		"description": "Complex saddle surface",
		"config": 102, # 01100110 - different alternating
		"densities": [0.3, 0.7, 0.7, 0.3, 0.3, 0.7, 0.7, 0.3]
	},
	{
		"name": "Case 10: Bridge",
		"description": "Bridge connecting surfaces",
		"config": 60, # 00111100 - creates bridge
		"densities": [0.3, 0.3, 0.7, 0.7, 0.7, 0.7, 0.3, 0.3]
	},
	{
		"name": "Case 11: Complex Surface",
		"description": "Complex multi-surface",
		"config": 90, # 01011010 - complex pattern
		"densities": [0.3, 0.7, 0.3, 0.7, 0.7, 0.3, 0.7, 0.3]
	},
	{
		"name": "Case 12: Asymmetric",
		"description": "Asymmetric surface pattern",
		"config": 105, # 01101001 - asymmetric
		"densities": [0.7, 0.3, 0.3, 0.7, 0.3, 0.7, 0.7, 0.3]
	},
	{
		"name": "Case 13: Nearly Full",
		"description": "Seven vertices inside",
		"config": 127, # 01111111 - vertex 7 outside
		"densities": [0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.3]
	},
	{
		"name": "Case 14: Full",
		"description": "All vertices inside surface",
		"config": 255, # 11111111 - all vertices inside
		"densities": [0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7]
	}
]

@export var case_spacing: float = 2.0  # Distance between cases
@export var case_scale: float = 0.5  # Scale of each example
## How much of the lookup table's operation is drawn. Replaces the old
## show_wireframes / show_labels booleans, whose two shipped `true` values are the
## `expression` rung — the same nodes, built by the same calls, in the same order.
@export_enum("expression", "outcome", "operands", "trace") var workings: String = "expression"
## Where the eight corner samples sit relative to the threshold. Classification is
## untouched at every rung; only the interpolated crossing moves.
@export_enum("even", "starved", "swollen", "brimming") var margin: String = "even"
@export var animate_threshold: bool = false
## CAPTURE ONLY — see _build_capture_anchor(). Reachable by direct property
## assignment (dna.fixture, the sweep) and by NOTHING a map can write:
## _read_metadata_overrides deliberately does not read config_capture_anchor, so no
## token can switch it on. That gating is load-bearing, not tidy — see the function.
@export var capture_anchor: String = "off"

# Camera controls
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 8.0
@export var max_zoom: float = 30.0
var current_zoom: float = 10.0
var camera_controller: Node3D

var labels: Array[Label3D] = []
var meshes: Array[MeshInstance3D] = []
var animation_time: float = 0.0

## Only what THIS script added. GridInteractablesComponent attaches a _RotationTimer
## to the root after spawn and the .tscn ships a CameraController, a Lighting rig, a
## WorldEnvironment and a UI Control; the old KEY_R path and _exit_tree freed every
## child of the root, which took all of those with them.
var _owned: Array[Node] = []
var _built: bool = false

func _ready() -> void:
	print("🔮 Marching Cubes: Demonstrating 15 unique surface cases...")

	_read_metadata_overrides()

	# Get camera controller reference
	camera_controller = get_node("CameraController")
	if camera_controller == null:
		camera_controller = get_parent().get_node("CameraController")

	_build()

func _process(delta: float) -> void:
	if animate_threshold:
		animation_time += delta
		animate_cases()


# ── Axis resolution ───────────────────────────────────────────────────────────

## The validated word. An unrecognised value resolves to the shipped rung rather
## than to a half-built branch — the failure mode a mistyped registry produced on
## science_screen, where an invalid value fell through to a default and sixteen
## identical frames were published as an experiment.
func _workings() -> String:
	return workings if WORKINGS.has(workings) else String(WORKINGS[0])

func _margin() -> String:
	return margin if MARGINS.has(margin) else String(MARGINS[0])

func _shows_sheet() -> bool:
	return _workings() != "operands"

func _shows_cage() -> bool:
	return _workings() != "outcome"

func _shows_labels() -> bool:
	var w: String = _workings()
	return w == "expression" or w == "trace"

func _shows_crossings() -> bool:
	return _workings() == "trace"

## The "outside" sample value. `even` returns the literal the chunk fill has always
## used, so the default is a short-circuit and not a recomputation.
func _outside_value() -> float:
	var m: String = _margin()
	if m == "even":
		return SHIPPED_OUTSIDE
	var pair: Array = MARGIN_PAIRS[m]
	return float(pair[0])

## The eight corner densities for a case. `even` returns the case's own literal
## array — the very object the file has always handed to the generator — so every
## existing placement builds a byte-identical density field and the same ArrayMesh.
## Every other rung remaps by CLASS, so the configuration index cannot change.
func _densities_for(case_data: Dictionary) -> Array:
	var m: String = _margin()
	if m == "even":
		return case_data.densities
	var pair: Array = MARGIN_PAIRS[m]
	var outside: float = float(pair[0])
	var inside: float = float(pair[1])
	var out: Array = []
	for d in case_data.densities:
		out.append(inside if float(d) > THRESHOLD else outside)
	return out

## Where the crossing lands, measured from the INSIDE corner toward the outside one.
## calculate_edge_intersections computes t = (threshold - d1) / (d2 - d1); with an
## inside value n and an outside value o that is (n - threshold) / (n - o).
func _crossing_t(which: String) -> float:
	var pair: Array = MARGIN_PAIRS.get(which, MARGIN_PAIRS["even"])
	var span: float = float(pair[1]) - float(pair[0])
	if absf(span) < 0.0001:
		return 0.5
	return (float(pair[1]) - THRESHOLD) / span


# ── Config ────────────────────────────────────────────────────────────────────

## Guarded. The old body was a bare `pass`, so nothing reached an assignment at all.
## It now stamps config into metadata, re-reads it, and rebuilds when — and only
## when — a value the build actually reads has changed.
##
## TWELVE PLACEMENTS in eleven maps, none of them touched. ELEVEN reach the artifact
## by paths that never call this method at all: two bare tokens and one carrying only
## a rotation (`fifteen_cases_demo:90`) leave merged_config empty, so
## _apply_artifact_config is skipped outright, and eight exhibit_furniture
## `#mount:fifteen_cases_demo` placements go through _mount_artifact, which
## instantiates, positions and adds the child without configuring it. The TWELFTH,
## curation_station in Curation_Bay_isosurfaces_0, DOES call it — with
## {"emissive": false}, a key no build path reads — so the signature comes back
## unchanged and the guard returns before any teardown.
func apply_grid_config(config_data: Dictionary) -> void:
	var before: String = _config_signature()
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if not _built:
		return
	if _config_signature() == before:
		return
	_rebuild()

func _config_signature() -> String:
	return "%s|%s|%.4f|%.4f" % [_workings(), _margin(), case_spacing, case_scale]

func _read_metadata_overrides() -> void:
	if has_meta("config_workings"):
		var w: String = str(get_meta("config_workings")).strip_edges().to_lower()
		if WORKINGS.has(w):
			workings = w
	if has_meta("config_margin"):
		var m: String = str(get_meta("config_margin")).strip_edges().to_lower()
		if MARGINS.has(m):
			margin = m
	if has_meta("config_case_spacing"):
		case_spacing = float(str(get_meta("config_case_spacing")))
	if has_meta("config_case_scale"):
		case_scale = float(str(get_meta("config_case_scale")))
	# config_capture_anchor is NOT read here, on purpose. See the export.


# ── Build ─────────────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	generate_fifteen_cases()
	if _shows_labels():
		create_labels()
	if capture_anchor == "on":
		_build_capture_anchor()

## Frees ONLY what this script added, then builds again — synchronously, in this
## frame. remove_child before queue_free so the old nodes leave the AABB
## immediately rather than at the end of the frame, which is what a capture
## measuring right after a config change would otherwise photograph.
func _rebuild() -> void:
	for n in _owned:
		if is_instance_valid(n):
			if n.get_parent() == self:
				remove_child(n)
			n.queue_free()
	_owned.clear()
	meshes.clear()
	labels.clear()
	_build()

func _add_owned(n: Node) -> void:
	add_child(n)
	_owned.append(n)

func generate_fifteen_cases() -> void:
	"""Generate visual representations of all 15 cases"""
	var rows: int = GRID_ROWS
	var cols: int = GRID_COLS

	for i in range(fifteen_cases.size()):
		var case_data = fifteen_cases[i]
		var row: int = i / cols
		var col: int = i % cols

		var cell_pos := Vector3(
			col * case_spacing - (cols - 1) * case_spacing * 0.5,
			0,
			row * case_spacing - (rows - 1) * case_spacing * 0.5
		)

		generate_case_mesh(case_data, cell_pos, i)

func generate_case_mesh(case_data: Dictionary, cell_pos: Vector3, case_index: int) -> void:
	"""Generate mesh for a specific marching cubes case using the advanced generator"""

	# The eight corner samples this rung of `margin` asks for. Read ONCE and shared
	# by the chunk, the bead colours and the crossing markers, so the picture cannot
	# disagree with itself.
	var densities: Array = _densities_for(case_data)

	# workings = outcome | expression | trace — the extracted sheet.
	if _shows_sheet():
		# Create a single-cube VoxelChunk for this case
		var chunk = create_voxel_chunk_from_case(densities)

		# Generate mesh using the advanced marching cubes generator
		var generator = MarchingCubesGenerator.new()
		generator.threshold = THRESHOLD  # Match our demo threshold
		generator.smoothing_enabled = true  # Enable smoothing for better surfaces

		var mesh = generator.generate_mesh_from_chunk(chunk)

		# Create visual representation
		var mesh_instance = create_case_mesh_instance(mesh, cell_pos, case_data, case_index)
		mesh_instance.scale = Vector3.ONE * case_scale
		_add_owned(mesh_instance)
		meshes.append(mesh_instance)

	# workings = expression | operands | trace — the cage and the corner samples,
	# which is the whole of what the extractor is given.
	if _shows_cage():
		var wireframe = create_wireframe_cube(cell_pos, densities)
		wireframe.scale = Vector3.ONE * case_scale
		_add_owned(wireframe)

func create_voxel_chunk_from_case(densities: Array) -> VoxelChunk:
	"""Create a VoxelChunk from case data for the advanced generator"""
	var chunk = VoxelChunk.new()
	chunk.chunk_size = Vector3i(2, 2, 2)  # 2x2x2 to contain one marching cube
	chunk.world_position = Vector3.ZERO

	# Set densities according to marching cubes vertex ordering
	var cube_vertex_positions = [
		Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(0, 1, 0),  # Bottom face
		Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(1, 1, 1), Vector3i(0, 1, 1)   # Top face
	]

	# Initialize chunk with default air density.
	#
	# THIS FILL IS PART OF THE MARGIN AXIS, not a constant. The chunk is 2x2x2, so
	# seven neighbour cubes share corners with the case cube and generate their own
	# sheets wherever a case corner is inside. Leaving the fill at 0.3 while the case
	# corners moved would put those seven sheets at a DIFFERENT crossing from the
	# one the rung is arguing, and the cell would contradict itself.
	var outside: float = _outside_value()
	for x in range(chunk.chunk_size.x + 1):
		for y in range(chunk.chunk_size.y + 1):
			for z in range(chunk.chunk_size.z + 1):
				chunk.set_density(Vector3i(x, y, z), outside)  # Default outside value

	# Set the 8 cube vertices to match our case
	for i in range(8):
		var pos = cube_vertex_positions[i]
		chunk.set_density(pos, densities[i])

	return chunk

func create_case_mesh_instance(mesh: ArrayMesh, cell_pos: Vector3, case_data: Dictionary, case_index: int) -> MeshInstance3D:
	"""Create a MeshInstance3D for a generated marching cubes case"""
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Case_%d" % case_index
	mesh_instance.position = cell_pos

	if mesh != null and mesh.get_surface_count() > 0:
		mesh_instance.mesh = mesh

		# Create material — flat, non-reflective
		var material = StandardMaterial3D.new()
		material.albedo_color = get_case_color(case_index)
		material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides
		material.metallic = 0.0
		material.roughness = 1.0
		material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

		mesh_instance.set_surface_override_material(0, material)

		print("Case %d (%s): Generated mesh with %d surfaces" % [case_index, case_data.name, mesh.get_surface_count()])
	else:
		# No mesh generated - show indicator
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.08
		sphere_mesh.height = 0.16
		mesh_instance.mesh = sphere_mesh
		mesh_instance.position.y += 0.3

		var material = StandardMaterial3D.new()
		material.albedo_color = Color.GRAY
		material.emission_enabled = true
		material.emission = Color.GRAY * 0.5
		mesh_instance.set_surface_override_material(0, material)

		print("Case %d (%s): No mesh generated (config %d)" % [case_index, case_data.name, case_data.config])

	return mesh_instance

func get_cube_positions() -> Array:
	"""Get the 8 corner positions of a unit cube"""
	return [
		Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0),  # Bottom face
		Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)   # Top face
	]



func create_wireframe_cube(cell_pos: Vector3, densities: Array) -> Node3D:
	"""Create wireframe representation showing vertex states"""
	var wireframe_node = Node3D.new()
	wireframe_node.name = "Wireframe"
	wireframe_node.position = cell_pos

	var cube_positions = get_cube_positions()

	# Create vertex indicators
	for i in range(8):
		var vertex_sphere = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = CORNER_RADIUS
		sphere_mesh.height = CORNER_RADIUS * 2.0
		vertex_sphere.mesh = sphere_mesh
		vertex_sphere.position = cube_positions[i]

		# Color based on density (inside/outside). Every margin rung keeps its two
		# values on the same sides of the threshold, so these eight beads are the
		# same eight colours in the same eight places at all four values — which is
		# what makes the still legible as an argument rather than as a resize.
		var material = StandardMaterial3D.new()
		if densities[i] > THRESHOLD:
			material.albedo_color = Color.RED  # Inside surface
		else:
			material.albedo_color = Color.BLUE  # Outside surface
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.5
		vertex_sphere.set_surface_override_material(0, material)

		wireframe_node.add_child(vertex_sphere)

	# Create edge lines
	for edge in EDGE_CONNECTIONS:
		var line = create_edge_line(cube_positions[edge[0]], cube_positions[edge[1]])
		wireframe_node.add_child(line)

	# workings = trace — the interpolated crossings themselves.
	if _shows_crossings():
		add_crossing_markers(wireframe_node, cube_positions, densities)

	return wireframe_node

## workings = trace. One marker on every edge whose two ends disagree, standing at
## the interpolated crossing — computed with the generator's own formula so the
## marker is where the extracted vertex is, not near it. These points are the whole
## of what interpolation contributes; a finished sheet shows only how they were
## joined, and this rung shows them before the table has said.
func add_crossing_markers(parent: Node3D, cube_positions: Array, densities: Array) -> void:
	for edge in EDGE_CONNECTIONS:
		var a: int = int(edge[0])
		var b: int = int(edge[1])
		var da: float = float(densities[a])
		var db: float = float(densities[b])
		if (da < THRESHOLD) == (db < THRESHOLD):
			continue
		var t: float = clampf((THRESHOLD - da) / (db - da), 0.0, 1.0)

		var marker = MeshInstance3D.new()
		marker.name = "Crossing_%d_%d" % [a, b]
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = CROSSING_RADIUS
		sphere_mesh.height = CROSSING_RADIUS * 2.0
		marker.mesh = sphere_mesh
		var pa: Vector3 = cube_positions[a]
		var pb: Vector3 = cube_positions[b]
		marker.position = pa.lerp(pb, t)

		var material = StandardMaterial3D.new()
		material.albedo_color = CROSSING_COLOR
		material.emission_enabled = true
		material.emission = CROSSING_COLOR
		material.emission_energy_multiplier = 1.4
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		marker.set_surface_override_material(0, material)

		parent.add_child(marker)

func create_edge_line(start: Vector3, end: Vector3) -> MeshInstance3D:
	"""Create a line between two points"""
	var line_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	vertices.append(start)
	vertices.append(end)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	line_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = line_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.flags_unshaded = true
	material.vertex_color_use_as_albedo = false
	mesh_instance.set_surface_override_material(0, material)

	return mesh_instance

func create_labels() -> void:
	"""Create text labels for each case"""
	for i in range(fifteen_cases.size()):
		var case_data = fifteen_cases[i]
		var row: int = i / GRID_COLS
		var col: int = i % GRID_COLS

		var label_position = Vector3(
			col * case_spacing - (GRID_COLS - 1) * case_spacing * 0.5,
			-1.5,
			row * case_spacing - (GRID_ROWS - 1) * case_spacing * 0.5
		)

		var label = Label3D.new()
		label.text = "%s\n%s\nConfig: %d" % [case_data.name, case_data.description, case_data.config]
		label.position = label_position
		label.modulate = Color.WHITE
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

		_add_owned(label)
		labels.append(label)

func get_case_color(case_index: int) -> Color:
	"""Get a unique color for each case"""
	var hue = float(case_index) / float(fifteen_cases.size())
	return Color.from_hsv(hue, 0.8, 1.0)

func animate_cases() -> void:
	"""Animate the threshold to show how surfaces change"""
	var threshold = sin(animation_time) * 0.5 + 0.5  # Oscillate between 0 and 1

	# Update all mesh materials to show animation
	for i in range(meshes.size()):
		var mesh_instance = meshes[i]
		var material = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
		if material:
			material.emission_energy = 0.5 + threshold * 0.5


# ── The measured box ──────────────────────────────────────────────────────────

## Stand an INVISIBLE box (layers = 0, so it renders nothing and casts nothing)
## around the union of EVERY value's extent, not this variant's.
##
## WHY IT IS NEEDED. `workings = outcome` deletes fifteen wireframe cages and 120
## corner beads, and `margin` slides every interpolated vertex — which is to say
## both axes change the very MeshInstance3D set that _subtree_aabb measures. A
## camera fitted per variant would photograph each rung at its own magnification,
## and two frames taken from different distances are not comparable pixel to pixel
## at all. That is the frame-relative verdict already recorded from the PostCrisis
## pass, and it is exactly the shape this artifact would have produced.
##
## layers = 0 and never `visible = false`: Godot visibility is hierarchical and the
## render-layer mask is per-instance, so this stays in every AABB walk while being
## drawn by no camera in the game.
##
## WHY IT IS GATED OFF. GridInteractablesComponent._compute_local_aabb counts
## MeshInstance3D and hands the result to _auto_ground_artifact, which shifts the
## artifact by its own min_y. The union box reaches 0.975 where the shipped
## geometry stops at 0.75 — harmless on its own, since grounding reads only the
## minimum and this box shares the shipped minimum of -0.04 — but it is also what
## capture_multi_angle and sync_footprints measure, and a 9.015 m box where the
## registry records 8.79 would re-rate this artifact's footprint on the next
## measurement sweep. `capture_anchor` defaults to "off" and _read_metadata_overrides
## deliberately does not read it, so no map token can switch it on; only direct
## property assignment, which is what dna.fixture does, reaches it.
##
## Sized by CONSTRUCTION from the grid's own constants and the margin table, not
## measured from the built scene: a box measured per value would be a different box
## per value, which is the failure it exists to prevent.
func _build_capture_anchor() -> void:
	var half_x: float = (GRID_COLS - 1) * case_spacing * 0.5
	var half_z: float = (GRID_ROWS - 1) * case_spacing * 0.5

	# Per-cell envelope in cell-local units, before case_scale.
	#   low   the corner beads at -CORNER_RADIUS, which sit below every crossing
	#         (the smallest a crossing ever reaches is min(t, 1 - t) > 0).
	#   high  the neighbour cubes' sheets, which cross between a case corner at 1
	#         and the chunk fill at 2, so they reach 1 + t.
	var t_max: float = 0.0
	for i in MARGINS.size():
		t_max = maxf(t_max, _crossing_t(String(MARGINS[i])))
	var cell_lo: float = -CORNER_RADIUS * case_scale
	var cell_hi: float = (1.0 + t_max) * case_scale

	var lo := Vector3(-half_x + cell_lo, cell_lo, -half_z + cell_lo)
	var hi := Vector3(half_x + cell_hi, cell_hi, half_z + cell_hi)

	var anchor = MeshInstance3D.new()
	anchor.name = "CaptureAnchor"
	var box_mesh = BoxMesh.new()
	box_mesh.size = hi - lo
	anchor.mesh = box_mesh
	anchor.position = (lo + hi) * 0.5
	anchor.layers = 0
	_add_owned(anchor)


func _input(event: InputEvent) -> void:
	"""Handle input for interactive features"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				# Was "toggle wireframes" — now the axis that toggle became.
				workings = String(WORKINGS[(_workings_index() + 1) % WORKINGS.size()])
				print("Workings: %s" % workings)
				if _built:
					_rebuild()
			KEY_M:
				margin = String(MARGINS[(_margin_index() + 1) % MARGINS.size()])
				print("Margin: %s" % margin)
				if _built:
					_rebuild()
			KEY_L:
				# A pure view toggle on whatever labels this rung built. It does not
				# touch `workings`, so it can never desync the axis from the scene.
				for label in labels:
					if is_instance_valid(label):
						label.visible = not label.visible
			KEY_A:
				animate_threshold = !animate_threshold
				print("Animation: %s" % animate_threshold)
			KEY_R:
				# Regenerate cases. Frees ONLY what this script built — the old body
				# freed every child of the root, which included the CameraController
				# this script had just cached and any timer the grid had attached.
				if _built:
					_rebuild()
			KEY_EQUAL, KEY_PLUS:
				# Zoom in with + key
				zoom_camera(-zoom_speed)
			KEY_MINUS:
				# Zoom out with - key
				zoom_camera(zoom_speed)

	elif event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					# Zoom in with mouse wheel
					zoom_camera(-zoom_speed)
				MOUSE_BUTTON_WHEEL_DOWN:
					# Zoom out with mouse wheel
					zoom_camera(zoom_speed)

func _workings_index() -> int:
	var i: int = WORKINGS.find(_workings())
	return i if i >= 0 else 0

func _margin_index() -> int:
	var i: int = MARGINS.find(_margin())
	return i if i >= 0 else 0

func zoom_camera(delta: float) -> void:
	"""Zoom the camera in or out"""
	if camera_controller == null:
		return

	current_zoom = clamp(current_zoom + delta, min_zoom, max_zoom)

	# Update camera position - maintain the same angle but change distance
	var base_height = current_zoom * 0.4  # Height scales with distance
	var base_distance = current_zoom

	camera_controller.position = Vector3(0, base_height, base_distance)
	print("Camera zoom: %.1f (distance: %.1f)" % [current_zoom, base_distance])

func _enter_tree() -> void:
	print("""
🔮 Marching Cubes 15 Cases Demo
=============================
Controls:
- W: Cycle workings (expression / outcome / operands / trace)
- M: Cycle margin (even / starved / swollen / brimming)
- L: Show/hide labels
- A: Toggle animation
- R: Regenerate
- Mouse Wheel: Zoom in/out
- +/-: Zoom in/out (keyboard)

This demonstrates the 15 fundamental surface cases that can occur
in the Marching Cubes algorithm. Each case represents a unique
surface topology configuration.
""")

func _exit_tree() -> void:
	# ONLY what this script built. The old body freed every child without an owner,
	# which is every node the grid attaches after spawn as well.
	for n in _owned:
		if is_instance_valid(n):
			n.queue_free()
