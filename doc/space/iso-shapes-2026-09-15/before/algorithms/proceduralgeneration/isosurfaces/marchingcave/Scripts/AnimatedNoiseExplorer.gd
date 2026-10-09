extends MeshInstance3D

## Animated Noise Space Explorer
## Travels through the 4D noise space by animating the offset

# --- DNA (stage 2, promoted 2026-08-12) -------------------------------------
# THE FINDING THIS ARTIFACT IS SITTING ON: its extractor is a stub, and the stub is
# more honest about marching cubes than a working one would be. create_marching_cubes_mesh
# below does not march. It tests whether a cell's eight corners straddle iso_level and,
# if they do, emits all six faces of a full solid cube — no lookup table, no edge
# interpolation, no case index. What it draws is therefore NOT the surface. It is the
# set of cells in which the field changes its mind, which is exactly what a real marching
# cubes consumes and then throws away. The sequence's truth line is "define a field,
# extract a surface"; this artifact stopped one step short of the surface and left the
# intermediate on screen.
#
# extraction — WHICH ELEMENT OF THE LATTICE THE BOUNDARY IS WRITTEN ON. Four rungs, all
#   four built from the same density_field the loop already has, and the ladder is the
#   dimension of the answer: a sample, a point on an edge, a face, a cell.
#     cells      SHIPPED, and a short-circuit — the original face-emitting function is
#                called unchanged. A solid cube per straddling cell. The crude, honest
#                default: a mass where a boundary was promised. 917 cells, 5,502 quads.
#     faces      the cell faces the contour actually passes through — a face kept only
#                when its own four lattice corners disagree. A perforated stepped sheet
#                inside the block set, one lattice dimension closer to the surface.
#                1,940 distinct quads.
#     corners    a marker at every lattice point whose value exceeds iso_level. No
#                surface at all — the sampled field itself, before any decision. 2,272
#                of 4,913 points at the shipped settings.
#     crossings  a marker at the linearly interpolated point on every lattice edge whose
#                two ends disagree, t = (iso - a) / (b - a). This is the exact set of
#                vertices marching cubes would have produced, the surface as a point
#                cloud the extractor here never built. 1,024 of them.
#   MEASURED, not guessed, and the measurement changed the design. noise_3d, the straddle
#   test and all four extractors were re-implemented in Python against the shipped .tscn
#   values (chunk_scale 1.0, noise_scale 0.7, iso_level 0.0, 16 cells) and rasterised with
#   a z-buffer from the sweep's own standpoint, yaw 0.62 / pitch -0.26, at 300x300.
#   Against `cells`: faces differs in 26.31% of the frame, corners in 35.27%, crossings in
#   34.20%; corners and crossings differ from each other in 17.29%. Subject share of frame
#   34.50 / 33.08 / 13.90 / 6.32 percent respectively, so the point clouds really are a
#   dust and the two block rungs really do fill the same silhouette differently.
#   WHAT THE MEASUREMENT KILLED: the rung `faces` was designed as the outer SKIN of the
#   straddling set. It rasterises 0.00% different from `cells` — not small, zero. Every one
#   of the 3,486 faces the skin discards is interior and occluded, so under an opaque
#   material a mass and its own skin are the same photograph, and that rung would have
#   shipped two identical tiles and been filed INERT for a fact about occlusion. See
#   _extract_faces.
#   The word is NEW and it is the sequence's own verb. `trace` (fourier_transform,
#   spring_demo) was refused: its rungs are a one-dimensional signal plot's vocabulary
#   and a volume cannot answer them. `workings` (csg_difference_demo: outcome | trace |
#   operands | expression) was refused for a sharper reason — workings asks how much of
#   an operation a demonstration will DISCLOSE, and `cells` is not a fuller disclosure
#   than `crossings`, it is a cruder extractor. Different claim, different word.
#
# resolution — HOW FINELY THE FIELD IS SAMPLED. `var resolution = 16` was a bare local
#   literal inside generate_chunk, invisible to every map and every inspector, and it is
#   the single number that decides everything about this picture. Measured on the shipped
#   field: coarse = 8 gives 232 straddling cells of 0.125 m, a chunky handful of blocks;
#   mid = 16 SHIPPED gives 917 cells of 0.0625 m; fine = 24 gives 2,070 cells of 0.0417 m,
#   about 24,800 triangles, which is affordable. Same noise function, same threshold,
#   three different objects — the field is continuous and everything you see is an
#   artefact of a sampling rate nobody was told about.
#   Capped at 24 deliberately. 32 is 3,678 cells, and the rebuild is a triple GDScript
#   loop over cells-cubed that also runs every regenerate_interval while animating, so a
#   higher rung buys nothing and risks the watchdog.
#   The word is SHARED — from riemann_pump ("resolution is HOW FINE THE PARTITION IS ...
#   the partition is this artifact's own subject"), and with the same three rung names as
#   queer_marching_cave in this same sequence, deliberately, so the two can be read
#   against each other. There it is a cell size in metres, here a cell count per axis;
#   both name the shipped state `mid`. If a shared vocabulary is honest the two behave
#   alike under it, and that is itself a check on the bench.
#
# WHAT IS DECLINED, and it is the whole travel apparatus: animation_speed,
# regenerate_interval, animation_path and auto_start. This artifact's premise is motion —
# its own Info label reads "Traveling Through 4D Noise" — and a rate, an interval and a
# direction are precisely what one PNG cannot photograph. A sweep over animation_speed
# would publish frames differing only in where the clock happened to be: the info_board
# fault (six identical tiles from five duration exports) with a moving subject instead of
# a still one. The standing arrangement offered instead is the pair above — the two things
# that are true of the field whether or not anyone is travelling through it. The travel
# was only ever a way of showing that the field extends past the box; extraction=corners
# shows the same thing in one frame by drawing the field itself. Also declined:
# show_wireframe (a material flag, not a form) and mesh_color.
#
# DETERMINISM. There is no RNG here of any kind — noise_3d is three hardcoded
# trigonometric terms, and the file contains no randf, no randi and no FastNoiseLite.
# The nondeterminism is THE CLOCK: _process accumulates current_offset every frame and
# regenerates the mesh every regenerate_interval, so two tiles captured 1.5 s apart
# photograph two different fields of the same artifact and the sweep would report the
# shutter as an axis. dna.fixture pins auto_start = false, which freezes current_offset at
# Vector3.ZERO — the t=0 field, the only offset every viewer is guaranteed to have seen.
# That pin is only safe because of the second repair below.
#
# TWO STRUCTURAL REPAIRS, both part of the promotion:
#   1. _ready BUILDS UNCONDITIONALLY. generate_chunk() used to be reachable only through
#      start_animation(), which _ready called only when auto_start was true — so pinning
#      auto_start to false to freeze the clock produced NO MESH AT ALL, the "NO RENDER,
#      _ready is gated and builds nothing standalone" trap, and the fixture would have
#      scored a blank frame INERT. auto_start now governs only whether _process advances
#      the offset. For auto_start = true (the .tscn's value, and every placement's) the
#      end state is identical: one generate_chunk at offset zero, is_animating true.
#   2. apply_grid_config was `pass` — a config channel wired to nothing. It now writes the
#      keys to metadata, re-reads the two axes, and REBUILDS ONLY IF a value the build
#      reads actually changed. Unknown keys cannot move the signature, so a config dict
#      that names none of these axes is a no-op exactly as before.
#
# REACH. 23 placements in 11 maps by four paths — a bare cell in ISO_AnimatedNoise and
# two more in Trial_physarum_isosurfaces, a curation_station roster in
# Corridor_ISO_AnimatedNoise and in Curation_Bay_isosurfaces_2, sixteen
# exhibit_furniture#kind:plinth#size:m#mount:animated_noise_explorer across eight Trial_*
# museums, and two corridor pairs (voxel_noise_demo-> and mc_terrain_demo->) in
# Trial_physarum_isosurfaces. NOT ONE of them passes an axis key, and every one of them
# resolves extraction = cells, resolution = mid, which are exact no-ops: `cells` calls the
# original function unchanged, and `mid` returns the literal 16 that was already there.
const EXTRACTIONS: PackedStringArray = ["cells", "faces", "corners", "crossings"]
const RESOLUTIONS: PackedStringArray = ["mid", "coarse", "fine"]
## Marker half-extent as a fraction of the cell, for `corners` and `crossings`. Small
## enough that the lattice reads as separated points rather than a fused blob, large
## enough to survive a 760 px tile: at mid the cell is 0.0625 m, so a marker is 25 mm
## across against a 62.5 mm spacing.
const MARKER_FRACTION : float = 0.20

@export_group("Chunk Settings")
@export var chunk_scale : float = 1.0  # 1x1 meter cube
@export var noise_scale : float = 0.8  # Feature size
@export var iso_level : float = 0.0  # Surface threshold

@export_group("Extraction")
## What a straddling cell becomes. `cells` is the shipped stub, kept verbatim.
@export_enum("cells", "faces", "corners", "crossings") var extraction: String = "cells"
## How fine the partition is. mid = 16, the literal this used to hide in a local var.
@export_enum("mid", "coarse", "fine") var resolution: String = "mid"
## BENCH ONLY, default off. An invisible (layers = 0) box the size of the sampled volume,
## so the capture rig's AABB is the FIELD's extent and not the extent of whatever this
## particular value happened to build. Off by default because the grid auto-grounds an
## artifact by its measured AABB, and a 1 m box would shift every existing placement down
## by up to half a cell. Pinned on by dna.fixture, nowhere else.
@export var frame_anchor : bool = false

@export_group("Animation Settings")
@export var animation_speed : float = 0.5  # Speed of travel through noise space
@export var animation_path : Vector3 = Vector3(1, 0.5, 0.3)  # Direction in noise space
@export var regenerate_interval : float = 0.2  # Seconds between updates
@export var auto_start : bool = true

@export_group("Visual Settings")
@export var show_wireframe : bool = false
@export var mesh_color : Color = Color(0.9, 0.8, 0.7)

# Internal state
var current_offset : Vector3 = Vector3.ZERO
var time_since_last_gen : float = 0.0
var is_animating : bool = false
var array_mesh : ArrayMesh

## Nodes THIS SCRIPT created, and the only ones it is ever allowed to free. The .tscn
## gives this node no children at all, but GridInteractablesComponent attaches a
## _RotationTimer to spawned artifacts, so "free every child" is never safe here.
var _owned : Array[Node] = []
var _built : bool = false
var _build_signature : String = ""

func _ready() -> void:
	array_mesh = ArrayMesh.new()
	mesh = array_mesh

	_read_metadata_overrides()

	# UNCONDITIONAL. The field exists whether or not anybody is travelling through it;
	# this used to be reachable only through start_animation(). See repair 1 above.
	generate_chunk()
	_sync_frame_anchor()
	_built = true
	_build_signature = _config_signature()

	# auto_start now decides only whether _process advances the offset. With it true —
	# the .tscn's value and every placement's — the end state is exactly what
	# start_animation() produced: is_animating true, one chunk generated at offset zero.
	is_animating = auto_start

func _process(delta: float) -> void:
	if not is_animating:
		return

	# Move through noise space
	current_offset += animation_path * animation_speed * delta

	# Update position label
	update_position_label()

	# Check if it's time to regenerate
	time_since_last_gen += delta
	if time_since_last_gen >= regenerate_interval:
		time_since_last_gen = 0.0
		generate_chunk()

func update_position_label() -> void:
	"""Update the position display label"""
	var label = get_node_or_null("../Position")
	if label:
		label.text = "Offset: (%.1f, %.1f, %.1f)" % [current_offset.x, current_offset.y, current_offset.z]

func start_animation() -> void:
	is_animating = true
	generate_chunk()

func stop_animation() -> void:
	is_animating = false

func generate_chunk() -> void:
	"""Generate marching cubes mesh for current position in noise space"""
	var res_n : int = _resolution_cells()
	var density_field = generate_density_field(res_n)
	var mesh_data = _extract(density_field, res_n)

	# Update mesh
	array_mesh.clear_surfaces()
	if mesh_data.is_empty():
		return
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)

	# Apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = mesh_color
	material.metallic = 0.2
	material.roughness = 0.6
	material.cull_mode = StandardMaterial3D.CULL_DISABLED
	if show_wireframe:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.wireframe = true
	material_override = material

## mid returns the literal 16 that used to sit inside generate_chunk. A placement that
## names nothing lands on this branch and the number is the one that shipped.
func _resolution_cells() -> int:
	match resolution:
		"coarse":
			return 8
		"fine":
			return 24
	return 16

## THE SHORT-CIRCUIT. `cells` — the default, and every one of the 23 placements — calls
## create_marching_cubes_mesh with nothing changed but the name of its int parameter.
func _extract(density_field: Array, res_n: int) -> Array:
	match extraction:
		"faces":
			return _extract_faces(density_field, res_n)
		"corners":
			return _extract_corners(density_field, res_n)
		"crossings":
			return _extract_crossings(density_field, res_n)
	return create_marching_cubes_mesh(density_field, res_n)

func generate_density_field(res_n: int) -> Array:
	"""Generate 3D density field using noise at current offset"""
	var field = []
	var cell_size = chunk_scale / float(res_n)
	var center_offset = Vector3(res_n, res_n, res_n) * cell_size * 0.5

	for x in range(res_n + 1):
		var yz_slice = []
		for y in range(res_n + 1):
			var z_line = []
			for z in range(res_n + 1):
				var world_pos = Vector3(x, y, z) * cell_size - center_offset
				var noise_pos = (world_pos / chunk_scale) * noise_scale + current_offset

				# Simple noise-based density
				var density = noise_3d(noise_pos.x, noise_pos.y, noise_pos.z)
				z_line.append(density)
			yz_slice.append(z_line)
		field.append(yz_slice)

	return field

func noise_3d(x: float, y: float, z: float) -> float:
	"""Simple 3D noise using trigonometric functions"""
	# Combine multiple frequencies for organic look
	var n1 = sin(x * 3.14) * cos(y * 2.71) * sin(z * 1.61)
	var n2 = sin(x * 6.28 + 1.5) * cos(y * 5.42 + 2.3) * sin(z * 3.22 + 0.8)
	var n3 = sin(x * 12.56 + 0.7) * cos(y * 10.84 + 1.2) * sin(z * 6.44 + 1.9)

	return (n1 + n2 * 0.5 + n3 * 0.25) / 1.75

func create_marching_cubes_mesh(density_field: Array, res_n: int) -> Array:
	"""Create mesh from density field using simple marching cubes"""
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var cell_size = chunk_scale / float(res_n)
	var center_offset = Vector3(res_n, res_n, res_n) * cell_size * 0.5

	var vertex_index = 0

	for x in range(res_n):
		for y in range(res_n):
			for z in range(res_n):
				# Get 8 corner values
				var values = [
					density_field[x][y][z],
					density_field[x+1][y][z],
					density_field[x+1][y][z+1],
					density_field[x][y][z+1],
					density_field[x][y+1][z],
					density_field[x+1][y+1][z],
					density_field[x+1][y+1][z+1],
					density_field[x][y+1][z+1]
				]

				# Check if surface crosses this cell
				var has_positive = false
				var has_negative = false
				for v in values:
					if v > iso_level:
						has_positive = true
					else:
						has_negative = true

				if not (has_positive and has_negative):
					continue

				# Create simplified cube faces where density crosses threshold
				var pos = Vector3(x, y, z) * cell_size - center_offset

				# Add cube faces (simplified marching cubes)
				var cube_verts = [
					pos,
					pos + Vector3(cell_size, 0, 0),
					pos + Vector3(cell_size, 0, cell_size),
					pos + Vector3(0, 0, cell_size),
					pos + Vector3(0, cell_size, 0),
					pos + Vector3(cell_size, cell_size, 0),
					pos + Vector3(cell_size, cell_size, cell_size),
					pos + Vector3(0, cell_size, cell_size)
				]

				# Add faces
				var faces = [
					[0, 1, 2, 3, Vector3(0, -1, 0)],  # Bottom
					[4, 7, 6, 5, Vector3(0, 1, 0)],   # Top
					[0, 3, 7, 4, Vector3(-1, 0, 0)],  # Left
					[1, 5, 6, 2, Vector3(1, 0, 0)],   # Right
					[0, 4, 5, 1, Vector3(0, 0, -1)],  # Front
					[3, 2, 6, 7, Vector3(0, 0, 1)]    # Back
				]

				for face in faces:
					var normal = face[4]
					var v0 = cube_verts[face[0]]
					var v1 = cube_verts[face[1]]
					var v2 = cube_verts[face[2]]
					var v3 = cube_verts[face[3]]

					# Triangle 1
					vertices.append(v0)
					vertices.append(v1)
					vertices.append(v2)
					normals.append(normal)
					normals.append(normal)
					normals.append(normal)
					indices.append(vertex_index)
					indices.append(vertex_index + 1)
					indices.append(vertex_index + 2)
					vertex_index += 3

					# Triangle 2
					vertices.append(v0)
					vertices.append(v2)
					vertices.append(v3)
					normals.append(normal)
					normals.append(normal)
					normals.append(normal)
					indices.append(vertex_index)
					indices.append(vertex_index + 1)
					indices.append(vertex_index + 2)
					vertex_index += 3

	if vertices.is_empty():
		return []

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	return arrays


# ── The other three extractors ────────────────────────────────────────────────
#
# These are deliberately NOT folded into create_marching_cubes_mesh, and the duplicated
# quad-emission below is the price. That function is what 23 placements render; it is left
# byte for byte as it shipped so that "the default is a short-circuit" is a fact about the
# file and not a claim about my arithmetic.

## The eight corners of one cell, in the order the shipped extractor reads them.
func _cell_straddles(density_field: Array, x: int, y: int, z: int) -> bool:
	var values = [
		density_field[x][y][z],
		density_field[x+1][y][z],
		density_field[x+1][y][z+1],
		density_field[x][y][z+1],
		density_field[x][y+1][z],
		density_field[x+1][y+1][z],
		density_field[x+1][y+1][z+1],
		density_field[x][y+1][z+1]
	]
	var has_positive = false
	var has_negative = false
	for v in values:
		if v > iso_level:
			has_positive = true
		else:
			has_negative = true
	return has_positive and has_negative

## The lattice-corner offset of each entry in the cube_verts table below, so a face can be
## asked about its OWN four samples.
const CUBE_OFFSETS : Array = [
	Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 0, 1), Vector3i(0, 0, 1),
	Vector3i(0, 1, 0), Vector3i(1, 1, 0), Vector3i(1, 1, 1), Vector3i(0, 1, 1)
]

## extraction = faces. THE CELL FACES THE CONTOUR ACTUALLY PASSES THROUGH: a face survives
## only when its own four lattice corners disagree about iso_level. The result is a
## perforated, stepped sheet running through the middle of the block set — one lattice
## dimension closer to the surface than `cells`, and full of holes where a face of a
## straddling cell lies wholly inside or wholly outside. 1,940 distinct quads against the
## 5,502 that `cells` draws, at the shipped settings.
##
## THIS IS NOT WHAT THE DESIGN ASKED FOR, and the substitution was measured rather than
## preferred. The approved rung was the outer SKIN of the straddling set — a face kept only
## where its six-neighbour does not also straddle. I rasterised both from the sweep's own
## standpoint (yaw 0.62, pitch -0.26) at 300x300 with a z-buffer, and the skin differs from
## `cells` in EXACTLY 0.00% of the frame: 2,016 quads instead of 5,502, and every one of the
## 3,486 discarded faces is interior and occluded, so an opaque render of the mass and an
## opaque render of its own skin are the same photograph. That rung would have published two
## identical tiles and been filed INERT for a fact about occlusion. The crossed-face reading
## differs from `cells` in 26.31% of the frame by the same measurement.
func _extract_faces(density_field: Array, res_n: int) -> Array:
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var cell_size : float = chunk_scale / float(res_n)
	var center_offset : Vector3 = Vector3(res_n, res_n, res_n) * cell_size * 0.5

	var solid : Array = []
	for x in range(res_n):
		var yz_slice : Array = []
		for y in range(res_n):
			var z_line : Array = []
			for z in range(res_n):
				z_line.append(_cell_straddles(density_field, x, y, z))
			yz_slice.append(z_line)
		solid.append(yz_slice)

	var vertex_index : int = 0
	for x in range(res_n):
		for y in range(res_n):
			for z in range(res_n):
				if not solid[x][y][z]:
					continue
				var pos : Vector3 = Vector3(x, y, z) * cell_size - center_offset
				var cube_verts = [
					pos,
					pos + Vector3(cell_size, 0, 0),
					pos + Vector3(cell_size, 0, cell_size),
					pos + Vector3(0, 0, cell_size),
					pos + Vector3(0, cell_size, 0),
					pos + Vector3(cell_size, cell_size, 0),
					pos + Vector3(cell_size, cell_size, cell_size),
					pos + Vector3(0, cell_size, cell_size)
				]
				var faces = [
					[0, 1, 2, 3, Vector3(0, -1, 0)],  # Bottom
					[4, 7, 6, 5, Vector3(0, 1, 0)],   # Top
					[0, 3, 7, 4, Vector3(-1, 0, 0)],  # Left
					[1, 5, 6, 2, Vector3(1, 0, 0)],   # Right
					[0, 4, 5, 1, Vector3(0, 0, -1)],  # Front
					[3, 2, 6, 7, Vector3(0, 0, 1)]    # Back
				]
				for face in faces:
					var normal : Vector3 = face[4]
					# Does the contour pass through THIS face? Its own four lattice
					# corners have to disagree.
					var above : bool = false
					var below : bool = false
					for k in range(4):
						var o : Vector3i = CUBE_OFFSETS[face[k]]
						if density_field[x + o.x][y + o.y][z + o.z] > iso_level:
							above = true
						else:
							below = true
					if not (above and below):
						continue
					# A face shared by two straddling cells is ONE face. It is drawn by
					# the lower cell, as its +X/+Y/+Z; drawing it from both sides puts
					# two coplanar quads at identical depth and they z-fight.
					if normal.x < 0.0 or normal.y < 0.0 or normal.z < 0.0:
						var nx : int = x + int(normal.x)
						var ny : int = y + int(normal.y)
						var nz : int = z + int(normal.z)
						if nx >= 0 and nx < res_n and ny >= 0 and ny < res_n \
								and nz >= 0 and nz < res_n:
							if solid[nx][ny][nz]:
								continue
					var v0 : Vector3 = cube_verts[face[0]]
					var v1 : Vector3 = cube_verts[face[1]]
					var v2 : Vector3 = cube_verts[face[2]]
					var v3 : Vector3 = cube_verts[face[3]]
					vertices.append(v0)
					vertices.append(v1)
					vertices.append(v2)
					normals.append(normal)
					normals.append(normal)
					normals.append(normal)
					indices.append(vertex_index)
					indices.append(vertex_index + 1)
					indices.append(vertex_index + 2)
					vertex_index += 3
					vertices.append(v0)
					vertices.append(v2)
					vertices.append(v3)
					normals.append(normal)
					normals.append(normal)
					normals.append(normal)
					indices.append(vertex_index)
					indices.append(vertex_index + 1)
					indices.append(vertex_index + 2)
					vertex_index += 3

	return _arrays_or_empty(vertices, normals, indices)

## extraction = corners. NO SURFACE AT ALL: a marker at every lattice point whose value
## exceeds iso_level. This is the sampled field before any decision has been taken about
## it — 2,272 of 4,913 points at the shipped settings. It is also the one frame in which
## you can see that the voxel is an instrument.
func _extract_corners(density_field: Array, res_n: int) -> Array:
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var cell_size : float = chunk_scale / float(res_n)
	var center_offset : Vector3 = Vector3(res_n, res_n, res_n) * cell_size * 0.5
	var radius : float = cell_size * MARKER_FRACTION

	for x in range(res_n + 1):
		for y in range(res_n + 1):
			for z in range(res_n + 1):
				if not (density_field[x][y][z] > iso_level):
					continue
				var p : Vector3 = Vector3(x, y, z) * cell_size - center_offset
				_emit_marker(vertices, normals, indices, p, radius)

	return _arrays_or_empty(vertices, normals, indices)

## extraction = crossings. THE VERTICES MARCHING CUBES WOULD HAVE PRODUCED, and which this
## extractor never built: on every lattice edge whose two ends disagree, the linearly
## interpolated point t = (iso - a) / (b - a). 1,024 of them at the shipped settings — the
## surface as a point cloud, one step before it is joined up into triangles.
func _extract_crossings(density_field: Array, res_n: int) -> Array:
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var cell_size : float = chunk_scale / float(res_n)
	var center_offset : Vector3 = Vector3(res_n, res_n, res_n) * cell_size * 0.5
	var radius : float = cell_size * MARKER_FRACTION
	var steps : Array = [Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1)]

	for x in range(res_n + 1):
		for y in range(res_n + 1):
			for z in range(res_n + 1):
				var a : float = density_field[x][y][z]
				for step in steps:
					var bx : int = x + step.x
					var by : int = y + step.y
					var bz : int = z + step.z
					if bx > res_n or by > res_n or bz > res_n:
						continue
					var b : float = density_field[bx][by][bz]
					if (a > iso_level) == (b > iso_level):
						continue
					var t : float = 0.5
					if absf(b - a) > 0.000001:
						t = clampf((iso_level - a) / (b - a), 0.0, 1.0)
					var pa : Vector3 = Vector3(x, y, z) * cell_size - center_offset
					var pb : Vector3 = Vector3(bx, by, bz) * cell_size - center_offset
					_emit_marker(vertices, normals, indices, pa + (pb - pa) * t, radius)

	return _arrays_or_empty(vertices, normals, indices)

## One octahedron: eight flat-shaded triangles, symmetric so it reads as a dot from any
## angle, and 24 vertices rather than a sphere's hundreds — at `fine` there are 7,180 of
## these to build in a GDScript triple loop, which is why the topology is a constant and
## the only per-marker allocation is the six corner positions.
## Corner order: +X, -X, +Y, -Y, +Z, -Z. Winding is irrelevant (the material culls
## nothing) but the normals are not, so they are given exactly.
const OCTA_FACES : Array = [
	[0, 2, 4], [2, 1, 4], [1, 3, 4], [3, 0, 4],
	[2, 0, 5], [1, 2, 5], [3, 1, 5], [0, 3, 5]
]
const OCTA_N : float = 0.5773502691896258   # 1 / sqrt(3)
const OCTA_NORMALS : Array = [
	Vector3(OCTA_N, OCTA_N, OCTA_N), Vector3(-OCTA_N, OCTA_N, OCTA_N),
	Vector3(-OCTA_N, -OCTA_N, OCTA_N), Vector3(OCTA_N, -OCTA_N, OCTA_N),
	Vector3(OCTA_N, OCTA_N, -OCTA_N), Vector3(-OCTA_N, OCTA_N, -OCTA_N),
	Vector3(-OCTA_N, -OCTA_N, -OCTA_N), Vector3(OCTA_N, -OCTA_N, -OCTA_N)
]

func _emit_marker(vertices: PackedVector3Array, normals: PackedVector3Array,
		indices: PackedInt32Array, centre: Vector3, r: float) -> void:
	var corners : Array = [
		centre + Vector3(r, 0.0, 0.0),
		centre + Vector3(-r, 0.0, 0.0),
		centre + Vector3(0.0, r, 0.0),
		centre + Vector3(0.0, -r, 0.0),
		centre + Vector3(0.0, 0.0, r),
		centre + Vector3(0.0, 0.0, -r)
	]
	for f in range(OCTA_FACES.size()):
		var tri : Array = OCTA_FACES[f]
		var n : Vector3 = OCTA_NORMALS[f]
		var base : int = vertices.size()
		vertices.append(corners[tri[0]])
		vertices.append(corners[tri[1]])
		vertices.append(corners[tri[2]])
		normals.append(n)
		normals.append(n)
		normals.append(n)
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)

func _arrays_or_empty(vertices: PackedVector3Array, normals: PackedVector3Array,
		indices: PackedInt32Array) -> Array:
	if vertices.is_empty():
		return []
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


# ── Config ────────────────────────────────────────────────────────────────────

## GUARDED, and it used to be `pass`. GridInteractablesComponent sets every config key as
## `config_<key>` metadata on the artifact BEFORE it enters the tree and then calls this
## deferred, so _ready has already read the metadata and built with it; this second call
## must therefore be able to tell "nothing I read has changed" from a real edit. It
## rebuilds only when the signature moves. Every one of the 23 placements passes no axis
## key at all, so none of them reaches the rebuild.
func apply_grid_config(config: Dictionary) -> void:
	var before : String = _build_signature
	for k in config.keys():
		var sanitized : String = str(k).replace(":", "_").replace(",", "_").replace(" ", "_").replace("-", "_")
		if sanitized.is_valid_identifier():
			set_meta("config_%s" % sanitized, config[k])
	_read_metadata_overrides()
	if not _built:
		return
	if _config_signature() == before:
		return
	generate_chunk()
	_sync_frame_anchor()
	_build_signature = _config_signature()

## Only the two axes. Deliberately NOT chunk_scale / noise_scale / iso_level / the
## animation knobs: this method ignored every key before today, and widening it to honour
## keys nobody has ever sent would be a behaviour change hiding inside a promotion. An
## unrecognised value is dropped, not applied — the science_screen failure was a typo that
## nothing refused.
func _read_metadata_overrides() -> void:
	if has_meta("config_extraction"):
		var e : String = str(get_meta("config_extraction")).strip_edges().to_lower()
		if EXTRACTIONS.has(e):
			extraction = e
	if has_meta("config_resolution"):
		var r : String = str(get_meta("config_resolution")).strip_edges().to_lower()
		if RESOLUTIONS.has(r):
			resolution = r

func _config_signature() -> String:
	return "%s|%s|%.4f|%.4f|%.4f|%s" % [
		extraction, resolution, chunk_scale, noise_scale, iso_level, str(frame_anchor)]

## The bench's constant denominator. `corners` and `crossings` are point clouds whose
## extent differs from the cube mass by up to a cell, and resolution moves the outermost
## block by half a cell, so without this the four verdicts would be frame-relative — the
## example_1_3 fault, where three tiles were the same picture at three magnifications.
## layers = 0 rather than visible = false: it renders on no layer, so it costs no pixel,
## and it is the only node this script ever creates or frees.
func _sync_frame_anchor() -> void:
	if frame_anchor and _owned.is_empty():
		var anchor := MeshInstance3D.new()
		anchor.name = "FrameAnchor"
		var box := BoxMesh.new()
		box.size = Vector3(chunk_scale, chunk_scale, chunk_scale)
		anchor.mesh = box
		anchor.layers = 0
		add_child(anchor)
		_owned.append(anchor)
	elif not frame_anchor and not _owned.is_empty():
		for n in _owned:
			if is_instance_valid(n):
				n.queue_free()
		_owned.clear()

func _input(event: InputEvent) -> void:
	# Space to toggle animation
	if event.is_action_pressed("ui_accept"):
		if is_animating:
			stop_animation()
		else:
			start_animation()
