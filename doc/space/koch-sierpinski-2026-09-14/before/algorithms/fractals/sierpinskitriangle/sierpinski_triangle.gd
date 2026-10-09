extends Node3D

# Sierpinski Triangle - 3D Recursive Triangle Subdivision
# Starts with a 1-meter equilateral triangle and subdivides it recursively
# Creates a beautiful fractal pattern by removing the center triangle each time

# @identity
# essence: sierpinski(v1,v2,v3,d) = 3 * sierpinski(corners, midpoints, d+1), skip center triangle. D = log(3)/log(2) ~ 1.585.
# desire: To be walked through — 10m triangle rotated vertical, extruded per iteration, creating a fractal wall of triangular portals
# critical_parameter: extrusion_height — each iteration extrudes deeper, turning the 2D fractal into a 3D walkable relief; excision — where the middle the algorithm refuses to build actually goes (absence | ghost | rubble | cast | negative)
# triggers: subdivision_interval tick → all current triangles split into 3 → center removed → depth hue-shifts rainbow
# emerges: The central voids become corridors — the removed triangles are the spaces you walk through
# needs: VR walking [has via geometry], iteration control [missing]
# relationships: 2D cousin of sierpinski_pyramid and menger_sponge; the canonical D ~ 1.585 fractal dimension example
# truth: The Sierpinski triangle has zero area and infinite perimeter — it is the shape that taught mathematics that removal creates structure.

# Settings
@export var subdivision_interval: float = 1.0  # Time between subdivisions
@export var max_iterations: int = 6  # Maximum subdivision depth
@export var auto_start: bool = true  # Auto-start subdivision
@export var triangle_size: float = 10.0  # Size of initial triangle (meters) - much larger for walking
@export var triangle_thickness: float = 0.5  # Thickness of 3D triangles - thicker for visibility
@export var extrude_on_subdivision: bool = true  # Extrude triangles upward with each iteration
@export var extrusion_height: float = 1.5  # How much to extrude per iteration - larger for walking
@export var colorize_by_depth: bool = true  # Color triangles by subdivision depth
@export var initial_rotation_degrees: float = 90.0  # Rotate triangle to stand vertical for walking through

# ─────────────────────────────────────────────────────────────────────────────
# DNA PROMOTION (2026-08-02).
#
# This artifact's own truth line is "removal creates structure — the shape that
# taught mathematics that removal creates structure". Every iteration takes a
# triangle, finds its middle, and does not build it. The gasket IS its own
# discard: there is nothing in a Sierpinski triangle except the record of what
# was thrown away.
#
# So the axis is not how deep it goes or how thick the slabs are. It is the one
# question the algorithm never answers about itself:
#
#   excision   where the removed middle goes
#
#     absence | ghost | rubble | cast | negative
#
#   absence   nowhere. It was never made, and nobody asks. Every middle at every
#             depth is simply skipped, which is the definition of the fractal and
#             the legacy lineage, mesh for mesh.
#   ghost     it stays exactly where it was, as a pale translucent pane. The
#             silhouette closes up into a solid triangle and the holes are still
#             legible through it — the hole remembering the triangle it was.
#   rubble    it drops to the ground plane. Every middle from every depth lands
#             flat at y = 0, so the rising relief stands on a dark carpet of its
#             own offcuts, one per hole, all sizes mixed. What you cut away has
#             to go somewhere.
#   cast      it grows the other way. Each middle is built at MINUS its parent's
#             extrusion height, so the complement rises downward as a second,
#             solid relief. Two stepped forms nose to nose: the fractal and the
#             mould it came out of, both real.
#   negative  it is the ONLY thing built. The three corner triangles are computed
#             and recursed exactly as before but never given a mesh, so what
#             stands is the stack of discards alone — the offcut promoted to the
#             work. Same recursion, opposite subject.
#
# THE MATHEMATICS DOES NOT MOVE. subdivide_triangle computes the same midpoints,
# returns the same three corner triangles and recurses on the same set at every
# value; D = log(3)/log(2) is untouched. This axis changes only which of the
# pieces the algorithm produces get a body.
#
# WHAT IS DELIBERATELY NOT THE AXIS. subdivision_interval and max_iterations are
# the tempting knobs and both are rates or dials, not claims — an interval is
# invisible to a still, and "how many iterations" is a quantity, not an argument.
# colorize_by_depth is a colour. extrusion_height is a distance.
#
# STRICTLY ADDITIVE. There is no RNG anywhere in this file, so there is no stream
# to shift. `absence` adds nothing: the match block below falls through to `pass`,
# and _emit_corner is a straight pass-through to the original builder for every
# value except `negative`.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — where the removed middle goes. `absence` is the legacy lineage.
@export_enum("absence", "ghost", "rubble", "cast", "negative") var excision: String = "absence"

## The allow-list a map token is checked against — the same five words the
## @export_enum declares, same spelling, same order.
const EXCISIONS: PackedStringArray = ["absence", "ghost", "rubble", "cast", "negative"]

# Internal state
var current_iteration: int = 0
var subdivision_timer: float = 0.0
var is_subdividing: bool = false
var current_triangles: Array = []  # Array of triangle data

func _ready() -> void:
	_read_dna_meta()
	print("SierpinskiTriangle: Ready")
	print("SierpinskiTriangle: Will subdivide to %d iterations" % max_iterations)

	# Apply rotation to make triangle vertical for walking through
	var rotation_rad = deg_to_rad(initial_rotation_degrees)
	rotate_x(rotation_rad)

	# Create the initial triangle
	create_initial_triangle()

	# Start automatic subdivision if enabled
	if auto_start:
		is_subdividing = true
		print("SierpinskiTriangle: Auto-subdivision enabled")

func _process(delta: float) -> void:
	if not is_subdividing:
		return

	# Update timer
	subdivision_timer += delta

	# Check if it's time to subdivide
	if subdivision_timer >= subdivision_interval:
		subdivision_timer = 0.0
		perform_subdivision()

# Create the initial 1-meter equilateral triangle
func create_initial_triangle() -> void:
	# Create equilateral triangle vertices (1 meter)
	var height = triangle_size * sqrt(3.0) / 2.0  # Height of equilateral triangle

	var v1 = Vector3(-triangle_size / 2.0, 0, height / 3.0)  # Bottom left
	var v2 = Vector3(triangle_size / 2.0, 0, height / 3.0)   # Bottom right
	var v3 = Vector3(0, 0, -2.0 * height / 3.0)              # Top (centered)

	var triangle_data = {
		"v1": v1,
		"v2": v2,
		"v3": v3,
		"depth": 0,
		"y_offset": 0.0
	}

	create_triangle_mesh(triangle_data)
	current_triangles = [triangle_data]

	print("SierpinskiTriangle: Created initial triangle")

# Perform one subdivision iteration
func perform_subdivision() -> void:
	if current_iteration >= max_iterations:
		print("SierpinskiTriangle: Reached maximum iterations (%d)" % max_iterations)
		is_subdividing = false
		return

	current_iteration += 1
	print("SierpinskiTriangle: Subdivision iteration %d" % current_iteration)

	var new_triangles = []

	# For each triangle, subdivide into 3 smaller triangles
	for triangle in current_triangles:
		var subdivided = subdivide_triangle(triangle)
		new_triangles.append_array(subdivided)

	current_triangles = new_triangles

	print("SierpinskiTriangle: Created %d triangles" % current_triangles.size())

# Subdivide a triangle into 3 smaller triangles (Sierpinski pattern)
func subdivide_triangle(triangle: Dictionary) -> Array:
	var v1 = triangle.v1
	var v2 = triangle.v2
	var v3 = triangle.v3
	var depth = triangle.depth + 1
	var base_y = triangle.y_offset

	# Calculate midpoints of each edge
	var m1 = (v1 + v2) / 2.0  # Midpoint of bottom edge
	var m2 = (v2 + v3) / 2.0  # Midpoint of right edge
	var m3 = (v3 + v1) / 2.0  # Midpoint of left edge

	# Calculate new y offset if extruding
	var new_y_offset = base_y
	if extrude_on_subdivision:
		new_y_offset += extrusion_height

	# Create 3 corner triangles (skip the center triangle - that's what creates the fractal!)
	var triangles = []

	# Bottom-left triangle
	var t1 = {
		"v1": v1,
		"v2": m1,
		"v3": m3,
		"depth": depth,
		"y_offset": new_y_offset
	}
	_emit_corner(t1)
	triangles.append(t1)

	# Bottom-right triangle
	var t2 = {
		"v1": m1,
		"v2": v2,
		"v3": m2,
		"depth": depth,
		"y_offset": new_y_offset
	}
	_emit_corner(t2)
	triangles.append(t2)

	# Top triangle
	var t3 = {
		"v1": m3,
		"v2": m2,
		"v3": v3,
		"depth": depth,
		"y_offset": new_y_offset
	}
	_emit_corner(t3)
	triangles.append(t3)

	# Note: We intentionally skip the center triangle (m1, m2, m3)
	# This is what creates the Sierpinski fractal pattern!

	# EXCISION — where that skipped middle goes. Appended LAST, after the three
	# corner triangles above have been created in their original order, so
	# `absence` leaves every child index in this scene exactly where it was.
	var middle: Dictionary = {
		"v1": m1,
		"v2": m2,
		"v3": m3,
		"depth": depth,
		"y_offset": new_y_offset
	}
	match excision:
		"ghost":
			# In place, translucent: the hole keeps a pane of itself.
			_excise_mesh(middle, new_y_offset, Color(0.86, 0.92, 1.0), 0.28)
		"rubble":
			# Dropped to the ground plane — the offcut pile under the relief.
			_excise_mesh(middle, 0.0, Color(0.34, 0.32, 0.29), 1.0)
		"cast":
			# Grown the other way: the complement as a solid mirrored relief.
			_excise_mesh(middle, -new_y_offset, Color(0.13, 0.15, 0.20), 1.0)
		"negative":
			# The only thing built. Wears the depth hue the corners would have had.
			_excise_mesh(middle, new_y_offset, _depth_hue(depth), 1.0)
		_:
			pass                                   # "absence" — the legacy lineage

	return triangles

# Create a 3D mesh for a triangle
func create_triangle_mesh(triangle: Dictionary) -> void:
	var mesh_instance = MeshInstance3D.new()
	var mesh = create_extruded_triangle_mesh(triangle)
	mesh_instance.mesh = mesh

	# Create material with color based on depth
	var material = StandardMaterial3D.new()

	if colorize_by_depth:
		# Rainbow gradient by depth
		var hue = float(triangle.depth) / max_iterations
		material.albedo_color = Color.from_hsv(hue, 0.8, 0.9)
	else:
		# Classic fractal colors
		material.albedo_color = Color(0.2, 0.6, 0.9)

	material.metallic = 0.0
	material.roughness = 1.0

	# Make material double-sided for walking through
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Add slight emission for glowing effect
	if triangle.depth > 0:
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.2
		material.emission_energy = 0.3

	mesh_instance.material_override = material

	# Position at y_offset
	mesh_instance.position.y = triangle.y_offset

	# Hide first iteration (depth 0)
	if triangle.depth == 0:
		mesh_instance.visible = false

	add_child(mesh_instance)

# Create an extruded triangle mesh with proper 3D geometry
func create_extruded_triangle_mesh(triangle: Dictionary) -> ArrayMesh:
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var v1 = triangle.v1
	var v2 = triangle.v2
	var v3 = triangle.v3
	var thickness = triangle_thickness

	# Bottom face vertices (y = 0)
	var b1 = v1
	var b2 = v2
	var b3 = v3

	# Top face vertices (y = thickness)
	var t1 = v1 + Vector3(0, thickness, 0)
	var t2 = v2 + Vector3(0, thickness, 0)
	var t3 = v3 + Vector3(0, thickness, 0)

	# Calculate normal for top/bottom faces
	var edge1 = v2 - v1
	var edge2 = v3 - v1
	var face_normal = edge1.cross(edge2).normalized()

	# Bottom face (0, 1, 2)
	vertices.append(b1)
	vertices.append(b2)
	vertices.append(b3)
	normals.append(-face_normal)
	normals.append(-face_normal)
	normals.append(-face_normal)
	indices.append(0)
	indices.append(2)
	indices.append(1)

	# Top face (3, 4, 5)
	vertices.append(t1)
	vertices.append(t2)
	vertices.append(t3)
	normals.append(face_normal)
	normals.append(face_normal)
	normals.append(face_normal)
	indices.append(3)
	indices.append(4)
	indices.append(5)

	# Side faces (3 rectangular sides)
	# Side 1: b1-b2-t2-t1
	var side1_normal = edge1.cross(Vector3.UP).normalized()
	vertices.append(b1)  # 6
	vertices.append(b2)  # 7
	vertices.append(t2)  # 8
	vertices.append(t1)  # 9
	for i in range(4):
		normals.append(side1_normal)
	indices.append(6)
	indices.append(7)
	indices.append(8)
	indices.append(6)
	indices.append(8)
	indices.append(9)

	# Side 2: b2-b3-t3-t2
	edge2 = v3 - v2
	var side2_normal = edge2.cross(Vector3.UP).normalized()
	vertices.append(b2)  # 10
	vertices.append(b3)  # 11
	vertices.append(t3)  # 12
	vertices.append(t2)  # 13
	for i in range(4):
		normals.append(side2_normal)
	indices.append(10)
	indices.append(11)
	indices.append(12)
	indices.append(10)
	indices.append(12)
	indices.append(13)

	# Side 3: b3-b1-t1-t3
	var edge3 = v1 - v3
	var side3_normal = edge3.cross(Vector3.UP).normalized()
	vertices.append(b3)  # 14
	vertices.append(b1)  # 15
	vertices.append(t1)  # 16
	vertices.append(t3)  # 17
	for i in range(4):
		normals.append(side3_normal)
	indices.append(14)
	indices.append(15)
	indices.append(16)
	indices.append(14)
	indices.append(16)
	indices.append(17)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh

# Manual control functions
func start_subdivision() -> void:
	is_subdividing = true
	subdivision_timer = 0.0
	print("SierpinskiTriangle: Started manually")

func stop_subdivision() -> void:
	is_subdividing = false
	print("SierpinskiTriangle: Stopped manually")

func reset() -> void:
	# Clear all meshes
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()

	current_iteration = 0
	subdivision_timer = 0.0
	is_subdividing = false
	current_triangles.clear()

	# Recreate initial triangle
	create_initial_triangle()

	print("SierpinskiTriangle: Reset")

func step() -> void:
	perform_subdivision()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass


# ── DNA: THE EXCISION ────────────────────────────────────────────────────────

## Read a map token / grid config value if the placer left one. An unknown word
## keeps the default — a typo must not silently turn a gasket into a solid.
func _read_dna_meta() -> void:
	if has_meta("config_excision"):
		var raw: String = str(get_meta("config_excision")).strip_edges().to_lower()
		if EXCISIONS.has(raw):
			excision = raw
		else:
			push_warning("SierpinskiTriangle: unknown excision '%s' — keeping '%s'" % [raw, excision])


## The rainbow-by-depth hue create_triangle_mesh gives the kept corners, so
## `negative` reads as the same object seen inside out rather than as a new one.
func _depth_hue(depth: int) -> Color:
	if colorize_by_depth:
		return Color.from_hsv(float(depth) / float(max_iterations), 0.8, 0.9)
	return Color(0.2, 0.6, 0.9)


## Build the removed middle as a real slab, at whatever height this value sends
## it to. Uses the SAME extruded-triangle geometry as the kept corners, so the
## piece is exactly the one the algorithm declined to make — no new mathematics,
## only a body for an existing result.
func _excise_mesh(triangle: Dictionary, y: float, tint: Color, alpha: float) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = create_extruded_triangle_mesh(triangle)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	material.metallic = 0.0
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		material.emission_enabled = true
		material.emission = Color(tint.r, tint.g, tint.b) * 0.2
		material.emission_energy_multiplier = 0.3
	mesh_instance.material_override = material

	mesh_instance.position.y = y
	add_child(mesh_instance)


## The kept corners' one gate. `negative` computes and recurses on all three
## exactly as before and simply does not give them a body; every other value —
## including the default — falls straight through to the original builder.
func _emit_corner(triangle: Dictionary) -> void:
	if excision == "negative":
		return
	create_triangle_mesh(triangle)
