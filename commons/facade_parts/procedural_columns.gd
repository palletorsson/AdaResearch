class_name FacadeProceduralColumns
extends RefCounted

## Library of procedural architectural columns generated with SurfaceTool.
## These go beyond what CSG can do — twisted, helical, and profile-lathed forms.
## Each static method returns a MeshInstance3D (or Node3D with children) ready
## to add to a scene.
##
## Uses the same parametric-vertex -> index-generation -> ArrayMesh pattern as
## the Mobius strip in algorithms/alternativegeometries/mobiusstrip/.
##
## All methods receive (w: float, h: float, params: Dictionary) where
## w = cell width and h = cell height.


# ==========================================================================
# Column profile presets — 2D curves for the profile_column() lathe generator.
# Each entry is an Array of Vector2(radius_factor, normalized_height).
# radius_factor is multiplied by the column's base radius.
# ==========================================================================

const COLUMN_PROFILES := {
	"entasis": [
		Vector2(0.8, 0.0), Vector2(0.85, 0.1), Vector2(0.95, 0.25),
		Vector2(1.0, 0.33), Vector2(0.98, 0.5), Vector2(0.93, 0.7),
		Vector2(0.85, 0.9), Vector2(0.8, 1.0)
	],
	"baluster": [
		Vector2(0.6, 0.0), Vector2(0.8, 0.05), Vector2(1.0, 0.15),
		Vector2(1.1, 0.3), Vector2(1.0, 0.45), Vector2(0.7, 0.55),
		Vector2(0.5, 0.65), Vector2(0.45, 0.75), Vector2(0.5, 0.85),
		Vector2(0.6, 0.95), Vector2(0.7, 1.0)
	],
	"vase": [
		Vector2(0.4, 0.0), Vector2(0.5, 0.05), Vector2(0.8, 0.15),
		Vector2(1.1, 0.3), Vector2(1.2, 0.45), Vector2(1.0, 0.6),
		Vector2(0.6, 0.7), Vector2(0.4, 0.8), Vector2(0.45, 0.9),
		Vector2(0.55, 0.95), Vector2(0.5, 1.0)
	],
	"bamboo": [
		Vector2(0.9, 0.0), Vector2(1.0, 0.02), Vector2(0.85, 0.1),
		Vector2(0.85, 0.23), Vector2(1.0, 0.25), Vector2(0.85, 0.27),
		Vector2(0.85, 0.48), Vector2(1.0, 0.5), Vector2(0.85, 0.52),
		Vector2(0.85, 0.73), Vector2(1.0, 0.75), Vector2(0.85, 0.77),
		Vector2(0.85, 0.98), Vector2(1.0, 1.0)
	],
	"bone": [
		Vector2(1.0, 0.0), Vector2(1.1, 0.05), Vector2(0.8, 0.15),
		Vector2(0.6, 0.3), Vector2(0.55, 0.5), Vector2(0.6, 0.7),
		Vector2(0.8, 0.85), Vector2(1.1, 0.95), Vector2(1.0, 1.0)
	],
	"solomon_smooth": []  # Generated programmatically — see _get_solomon_smooth_profile()
}


# ==========================================================================
# Internal helpers
# ==========================================================================

## Generate the solomon_smooth profile programmatically.
## Produces a sinusoidal radius variation with ~40 points.
static func _get_solomon_smooth_profile(waves: float = 5.0,
		amplitude: float = 0.2, base_r: float = 0.8) -> Array:
	var profile: Array = []
	var point_count := 40
	for i in range(point_count + 1):
		var t := float(i) / float(point_count)
		var r := base_r + amplitude * sin(t * waves * TAU)
		profile.append(Vector2(r, t))
	return profile


## Resolve a profile by name or return the array directly.
static func _resolve_profile(profile_input, params: Dictionary) -> Array:
	if profile_input is String:
		if profile_input == "solomon_smooth":
			var waves: float = params.get("solomon_waves", 5.0)
			var amplitude: float = params.get("solomon_amplitude", 0.2)
			var base_r: float = params.get("solomon_base_r", 0.8)
			return _get_solomon_smooth_profile(waves, amplitude, base_r)
		elif COLUMN_PROFILES.has(profile_input):
			return COLUMN_PROFILES[profile_input]
		else:
			push_warning("FacadeProceduralColumns: Unknown profile '%s', using entasis" % profile_input)
			return COLUMN_PROFILES["entasis"]
	elif profile_input is Array:
		return profile_input
	return COLUMN_PROFILES["entasis"]


## Create the default stone material.
static func _make_material(params: Dictionary) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = params.get("color", Color(0.82, 0.76, 0.66))
	mat.roughness = params.get("roughness", 0.8)
	mat.metallic = params.get("metallic", 0.0)
	return mat


## Build an ArrayMesh from vertices/UVs/indices using SurfaceTool for normal generation.
## This is the core mesh-building pipeline used by all column generators.
static func _build_mesh(vertices: PackedVector3Array, uvs: PackedVector2Array,
		indices: PackedInt32Array, material: StandardMaterial3D) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Add all vertices with their UVs
	for i in range(vertices.size()):
		st.set_uv(uvs[i])
		st.add_vertex(vertices[i])

	# Add triangle indices
	for i in range(indices.size()):
		st.add_index(indices[i])

	# Auto-generate smooth normals and tangents
	st.generate_normals()
	st.generate_tangents()

	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, material)
	return mi


## Generate a cylinder mesh as ArrayMesh.
## Used for bases, capitals, straight columns, and cluster shafts.
## Origin is at the center of the cylinder. Axis is Y.
static func _cylinder_mesh(radius: float, height: float, segments: int,
		v_segments: int, material: StandardMaterial3D,
		y_offset: float = 0.0) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	var rings := v_segments + 1
	var cols := segments + 1

	# Generate vertex rings
	for j in range(rings):
		var v := float(j) / float(v_segments)
		var y := y_offset + v * height
		for i in range(cols):
			var u := float(i) / float(segments)
			var angle := u * TAU
			var x := cos(angle) * radius
			var z := sin(angle) * radius
			vertices.append(Vector3(x, y, z))
			uvs.append(Vector2(u, v))

	# Generate indices (two triangles per quad)
	for j in range(v_segments):
		for i in range(segments):
			var current := j * cols + i
			var next_col := j * cols + i + 1
			var next_row := (j + 1) * cols + i
			var next_both := (j + 1) * cols + i + 1

			# Triangle 1 (CCW winding for front face)
			indices.append(current)
			indices.append(next_row)
			indices.append(next_col)

			# Triangle 2
			indices.append(next_col)
			indices.append(next_row)
			indices.append(next_both)

	return _build_mesh(vertices, uvs, indices, material)


## Generate a disk (cap) mesh — flat circle at a given Y height.
static func _disk_mesh(radius: float, y: float, segments: int,
		material: StandardMaterial3D, face_up: bool = true) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	# Center vertex
	vertices.append(Vector3(0.0, y, 0.0))
	uvs.append(Vector2(0.5, 0.5))

	for i in range(segments + 1):
		var angle := float(i) / float(segments) * TAU
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		vertices.append(Vector3(x, y, z))
		uvs.append(Vector2(cos(angle) * 0.5 + 0.5, sin(angle) * 0.5 + 0.5))

	for i in range(segments):
		if face_up:
			indices.append(0)
			indices.append(i + 1)
			indices.append(i + 2)
		else:
			indices.append(0)
			indices.append(i + 2)
			indices.append(i + 1)

	return _build_mesh(vertices, uvs, indices, material)


## Generate a torus mesh centered at a given Y height.
## Used for base moldings and connecting bands.
static func _torus_mesh(major_radius: float, minor_radius: float, y: float,
		ring_segments: int, tube_segments: int,
		material: StandardMaterial3D) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	var ring_cols := ring_segments + 1
	var tube_cols := tube_segments + 1

	for i in range(ring_cols):
		var u := float(i) / float(ring_segments)
		var theta := u * TAU
		var ring_center := Vector3(cos(theta) * major_radius, y, sin(theta) * major_radius)
		var outward := Vector3(cos(theta), 0.0, sin(theta))

		for j in range(tube_cols):
			var v := float(j) / float(tube_segments)
			var phi := v * TAU
			var point := ring_center + outward * (cos(phi) * minor_radius) + Vector3(0, sin(phi) * minor_radius, 0)
			vertices.append(point)
			uvs.append(Vector2(u, v))

	# Indices
	for i in range(ring_segments):
		for j in range(tube_segments):
			var current := i * tube_cols + j
			var next_ring := (i + 1) * tube_cols + j
			var next_tube := i * tube_cols + j + 1
			var next_both := (i + 1) * tube_cols + j + 1

			indices.append(current)
			indices.append(next_ring)
			indices.append(next_tube)

			indices.append(next_tube)
			indices.append(next_ring)
			indices.append(next_both)

	return _build_mesh(vertices, uvs, indices, material)


## Add a simple base molding: plinth (box-like disk) + torus.
static func _add_base(root: Node3D, radius: float, base_h: float,
		segments: int, material: StandardMaterial3D) -> void:
	# Plinth — slightly wider cylinder
	var plinth_h := base_h * 0.5
	var plinth := _cylinder_mesh(radius * 1.3, plinth_h, segments, 2, material, 0.0)
	plinth.name = "BasePlinth"
	root.add_child(plinth)

	# Top disk of plinth
	var plinth_cap := _disk_mesh(radius * 1.3, plinth_h, segments, material, true)
	plinth_cap.name = "BasePlinthCap"
	root.add_child(plinth_cap)

	# Bottom disk of plinth
	var plinth_bottom := _disk_mesh(radius * 1.3, 0.0, segments, material, false)
	plinth_bottom.name = "BasePlinthBottom"
	root.add_child(plinth_bottom)

	# Torus molding
	var torus := _torus_mesh(radius * 1.1, base_h * 0.25, plinth_h + base_h * 0.25,
		segments, 8, material)
	torus.name = "BaseTorus"
	root.add_child(torus)


## Add a simple capital: echinus (flared cylinder) + abacus (wider disk).
static func _add_capital(root: Node3D, radius: float, capital_h: float,
		shaft_top_y: float, segments: int, material: StandardMaterial3D) -> void:
	var echinus_h := capital_h * 0.6
	var abacus_h := capital_h * 0.4

	# Echinus — slightly wider cylinder
	var echinus := _cylinder_mesh(radius * 1.2, echinus_h, segments, 2, material, shaft_top_y)
	echinus.name = "Echinus"
	root.add_child(echinus)

	# Abacus — flat wide disk on top
	var abacus_y := shaft_top_y + echinus_h
	var abacus := _cylinder_mesh(radius * 1.4, abacus_h, segments, 1, material, abacus_y)
	abacus.name = "Abacus"
	root.add_child(abacus)

	# Top cap
	var cap := _disk_mesh(radius * 1.4, abacus_y + abacus_h, segments, material, true)
	cap.name = "AbacusCap"
	root.add_child(cap)


# ==========================================================================
# COLUMN TYPE 1: SOLOMONIC (Barley-Twist)
# ==========================================================================

## Generate a Solomonic (barley-twist) column.
static func solomonic(w: float, h: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "ColSolomonic"

	var base_height: float = params.get("base_height", h * 0.05)
	var capital_height: float = params.get("capital_height", h * 0.05)
	var shaft_height: float = h - base_height - capital_height
	var twist_count: float = params.get("twist_count", 6.0)
	var twist_radius: float = params.get("twist_radius", w * 0.04)
	var shaft_radius: float = params.get("shaft_radius", w * 0.1)
	var v_segments: int = params.get("v_segments", 64)
	var h_segments: int = params.get("h_segments", 16)
	var material := _make_material(params)

	var cx := w * 0.5

	# Generate the twisted shaft mesh
	var shaft := _generate_solomonic_shaft(shaft_radius, shaft_height, twist_count,
		twist_radius, v_segments, h_segments, base_height, material)
	shaft.name = "SolomonicShaft"
	shaft.position.x = cx
	root.add_child(shaft)

	# Base and capital — use simple cylindrical forms offset to column center
	var base_root := Node3D.new()
	base_root.name = "Base"
	base_root.position.x = cx
	root.add_child(base_root)
	_add_base(base_root, shaft_radius + twist_radius, base_height, h_segments, material)

	var cap_root := Node3D.new()
	cap_root.name = "Capital"
	cap_root.position.x = cx
	root.add_child(cap_root)
	_add_capital(cap_root, shaft_radius + twist_radius, capital_height,
		base_height + shaft_height, h_segments, material)

	return root


## Internal: generate the solomonic shaft geometry.
static func _generate_solomonic_shaft(shaft_radius: float, shaft_height: float,
		twist_count: float, twist_radius: float, v_segments: int,
		h_segments: int, y_offset: float, material: StandardMaterial3D,
		phase_offset: float = 0.0,
		flute_count: int = 0, flute_depth: float = 0.0) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	var rings := v_segments + 1
	var cols := h_segments + 1

	for j in range(rings):
		var t := float(j) / float(v_segments)
		var y := y_offset + t * shaft_height

		# Helix center position at this height
		var helix_angle := t * twist_count * TAU + phase_offset
		var center_x := twist_radius * cos(helix_angle)
		var center_z := twist_radius * sin(helix_angle)

		# Local coordinate frame for the cross-section.
		var radial_out: Vector3
		if twist_radius > 0.001:
			radial_out = Vector3(center_x, 0.0, center_z).normalized()
		else:
			radial_out = Vector3(1.0, 0.0, 0.0)

		# binormal: perpendicular to radial_out in XZ plane
		var binormal := Vector3(-radial_out.z, 0.0, radial_out.x)

		for i in range(cols):
			var u := float(i) / float(h_segments)
			var angle := u * TAU

			# Calculate the effective radius, applying fluting if requested
			var r := shaft_radius
			if flute_count > 0 and flute_depth > 0.0:
				var flute_angle := angle * float(flute_count)
				var flute_factor := cos(flute_angle)
				if flute_factor > 0.0:
					r -= shaft_radius * flute_depth * flute_factor * flute_factor

			# For a proper tube cross-section: circle in plane of (radial_out, Y_axis)
			var vx := center_x + r * cos(angle) * radial_out.x
			var vy := y + r * sin(angle)
			var vz := center_z + r * cos(angle) * radial_out.z

			vertices.append(Vector3(vx, vy, vz))
			uvs.append(Vector2(u, t))

	# Generate triangle indices
	for j in range(v_segments):
		for i in range(h_segments):
			var current := j * cols + i
			var next_col := j * cols + i + 1
			var next_row := (j + 1) * cols + i
			var next_both := (j + 1) * cols + i + 1

			indices.append(current)
			indices.append(next_row)
			indices.append(next_col)

			indices.append(next_col)
			indices.append(next_row)
			indices.append(next_both)

	return _build_mesh(vertices, uvs, indices, material)


# ==========================================================================
# COLUMN TYPE 2: DOUBLE HELIX (DNA / Intertwined)
# ==========================================================================

## Generate a double helix column — two shafts spiraling around each other.
static func double_helix(w: float, h: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "ColDoubleHelix"

	var base_height: float = params.get("base_height", h * 0.05)
	var capital_height: float = params.get("capital_height", h * 0.05)
	var shaft_height: float = h - base_height - capital_height
	var twist_count: float = params.get("twist_count", 4.0)
	var helix_radius: float = params.get("helix_radius", w * 0.08)
	var shaft_radius: float = params.get("shaft_radius", w * 0.06)
	var band_count: int = params.get("band_count", 0)
	var v_segments: int = params.get("v_segments", 64)
	var h_segments: int = params.get("h_segments", 16)
	var material := _make_material(params)

	var cx := w * 0.5

	# Strand A: phase = 0
	var strand_a := _generate_solomonic_shaft(shaft_radius, shaft_height, twist_count,
		helix_radius, v_segments, h_segments, base_height, material, 0.0)
	strand_a.name = "StrandA"
	strand_a.position.x = cx
	root.add_child(strand_a)

	# Strand B: phase = PI (180 offset)
	var strand_b := _generate_solomonic_shaft(shaft_radius, shaft_height, twist_count,
		helix_radius, v_segments, h_segments, base_height, material, PI)
	strand_b.name = "StrandB"
	strand_b.position.x = cx
	root.add_child(strand_b)

	# Optional connecting bands (torus rings at regular intervals)
	if band_count > 0:
		var band_radius := helix_radius * 1.2
		var tube_radius := shaft_radius * 0.2
		for i in range(band_count):
			var t := float(i + 1) / float(band_count + 1)
			var band_y := base_height + t * shaft_height
			var band := _torus_mesh(band_radius, tube_radius, band_y, 16, 6, material)
			band.name = "Band_%d" % i
			band.position.x = cx
			root.add_child(band)

	# Base — wider to encompass both strands
	var total_radius := helix_radius + shaft_radius
	var base_root := Node3D.new()
	base_root.name = "Base"
	base_root.position.x = cx
	root.add_child(base_root)
	_add_base(base_root, total_radius, base_height, h_segments, material)

	# Capital
	var cap_root := Node3D.new()
	cap_root.name = "Capital"
	cap_root.position.x = cx
	root.add_child(cap_root)
	_add_capital(cap_root, total_radius, capital_height,
		base_height + shaft_height, h_segments, material)

	return root


# ==========================================================================
# COLUMN TYPE 3: STRAIGHT (Simple Cylinder)
# ==========================================================================

## Generate a simple straight cylindrical column.
static func straight(w: float, h: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "ColStraight"

	var base_height: float = params.get("base_height", h * 0.05)
	var capital_height: float = params.get("capital_height", h * 0.05)
	var shaft_height: float = h - base_height - capital_height
	var radius: float = params.get("radius", w * 0.1)
	var segments: int = params.get("segments", 24)
	var material := _make_material(params)

	var cx := w * 0.5

	# Shaft cylinder
	var shaft := _cylinder_mesh(radius, shaft_height, segments, 8, material, base_height)
	shaft.name = "Shaft"
	shaft.position.x = cx
	root.add_child(shaft)

	# Bottom cap of shaft
	var bottom_cap := _disk_mesh(radius, base_height, segments, material, false)
	bottom_cap.name = "ShaftBottomCap"
	bottom_cap.position.x = cx
	root.add_child(bottom_cap)

	# Top cap of shaft
	var top_cap := _disk_mesh(radius, base_height + shaft_height, segments, material, true)
	top_cap.name = "ShaftTopCap"
	top_cap.position.x = cx
	root.add_child(top_cap)

	# Base
	var base_root := Node3D.new()
	base_root.name = "Base"
	base_root.position.x = cx
	root.add_child(base_root)
	_add_base(base_root, radius, base_height, segments, material)

	# Capital
	var cap_root := Node3D.new()
	cap_root.name = "Capital"
	cap_root.position.x = cx
	root.add_child(cap_root)
	_add_capital(cap_root, radius, capital_height,
		base_height + shaft_height, segments, material)

	return root


# ==========================================================================
# COLUMN TYPE 4: PROFILE COLUMN (Lathe / Surface of Revolution)
# ==========================================================================

## Generate a column by revolving a 2D profile curve around the Y axis.
static func profile_column(w: float, h: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "ColProfile"

	var base_height: float = params.get("base_height", h * 0.05)
	var capital_height: float = params.get("capital_height", h * 0.05)
	var shaft_height: float = h - base_height - capital_height
	var radius: float = params.get("radius", w * 0.1)
	var segments: int = params.get("segments", 24)
	var profile_input = params.get("profile", "entasis")
	var material := _make_material(params)

	var cx := w * 0.5

	var profile: Array = _resolve_profile(profile_input, params)

	# Generate the lathed shaft
	var shaft := _generate_lathe_mesh(profile, radius, shaft_height, segments,
		base_height, material)
	shaft.name = "ProfileShaft"
	shaft.position.x = cx
	root.add_child(shaft)

	# Cap the top and bottom if the profile doesn't close to zero radius
	var bottom_r: float = radius
	if profile.size() > 0:
		bottom_r = profile[0].x * radius
	var top_r: float = radius
	if profile.size() > 0:
		top_r = profile[profile.size() - 1].x * radius

	if bottom_r > 0.01:
		var bottom_cap := _disk_mesh(bottom_r, base_height, segments, material, false)
		bottom_cap.name = "ShaftBottomCap"
		bottom_cap.position.x = cx
		root.add_child(bottom_cap)

	if top_r > 0.01:
		var top_cap := _disk_mesh(top_r, base_height + shaft_height, segments, material, true)
		top_cap.name = "ShaftTopCap"
		top_cap.position.x = cx
		root.add_child(top_cap)

	# Base
	var max_profile_r := 0.0
	for pt in profile:
		max_profile_r = maxf(max_profile_r, pt.x)
	var effective_radius := max_profile_r * radius

	var base_root := Node3D.new()
	base_root.name = "Base"
	base_root.position.x = cx
	root.add_child(base_root)
	_add_base(base_root, effective_radius, base_height, segments, material)

	# Capital
	var cap_root := Node3D.new()
	cap_root.name = "Capital"
	cap_root.position.x = cx
	root.add_child(cap_root)
	_add_capital(cap_root, effective_radius, capital_height,
		base_height + shaft_height, segments, material)

	return root


## Internal: generate a surface-of-revolution mesh from a 2D profile.
static func _generate_lathe_mesh(profile: Array, radius: float,
		shaft_height: float, segments: int, y_offset: float,
		material: StandardMaterial3D) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	var profile_count := profile.size()
	if profile_count < 2:
		# Fallback: simple cylinder
		return _cylinder_mesh(radius, shaft_height, segments, 8, material, y_offset)

	var cols := segments + 1

	# Generate vertices: one ring per profile point
	for j in range(profile_count):
		var pt: Vector2 = profile[j]
		var r := pt.x * radius
		var y := y_offset + pt.y * shaft_height
		var v := pt.y  # UV v follows normalized height

		for i in range(cols):
			var u := float(i) / float(segments)
			var angle := u * TAU
			vertices.append(Vector3(cos(angle) * r, y, sin(angle) * r))
			uvs.append(Vector2(u, v))

	# Generate triangle indices
	for j in range(profile_count - 1):
		for i in range(segments):
			var current := j * cols + i
			var next_col := j * cols + i + 1
			var next_row := (j + 1) * cols + i
			var next_both := (j + 1) * cols + i + 1

			indices.append(current)
			indices.append(next_row)
			indices.append(next_col)

			indices.append(next_col)
			indices.append(next_row)
			indices.append(next_both)

	return _build_mesh(vertices, uvs, indices, material)


# ==========================================================================
# COLUMN TYPE 5: FLUTED TWIST
# ==========================================================================

## Generate a twisted column with fluting that follows the twist.
static func fluted_twist(w: float, h: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "ColFlutedTwist"

	var base_height: float = params.get("base_height", h * 0.05)
	var capital_height: float = params.get("capital_height", h * 0.05)
	var shaft_height: float = h - base_height - capital_height
	var twist_count: float = params.get("twist_count", 6.0)
	var twist_radius: float = params.get("twist_radius", w * 0.04)
	var shaft_radius: float = params.get("shaft_radius", w * 0.1)
	var flute_count: int = params.get("flute_count", 20)
	var flute_depth: float = params.get("flute_depth", 0.15)
	var v_segments: int = params.get("v_segments", 64)
	var h_segments: int = params.get("h_segments", 24)  # More for flute detail
	var material := _make_material(params)

	var cx := w * 0.5

	# Generate shaft with fluting baked in
	var shaft := _generate_solomonic_shaft(shaft_radius, shaft_height, twist_count,
		twist_radius, v_segments, h_segments, base_height, material, 0.0,
		flute_count, flute_depth)
	shaft.name = "FlutedTwistShaft"
	shaft.position.x = cx
	root.add_child(shaft)

	# Base and capital
	var total_radius := shaft_radius + twist_radius
	var base_root := Node3D.new()
	base_root.name = "Base"
	base_root.position.x = cx
	root.add_child(base_root)
	_add_base(base_root, total_radius, base_height, h_segments, material)

	var cap_root := Node3D.new()
	cap_root.name = "Capital"
	cap_root.position.x = cx
	root.add_child(cap_root)
	_add_capital(cap_root, total_radius, capital_height,
		base_height + shaft_height, h_segments, material)

	return root


# ==========================================================================
# COLUMN TYPE 6: CLUSTER (Gothic Pier)
# ==========================================================================

## Generate a Gothic clustered column.
static func cluster(w: float, h: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "ColCluster"

	var base_height: float = params.get("base_height", h * 0.05)
	var capital_height: float = params.get("capital_height", h * 0.05)
	var shaft_height: float = h - base_height - capital_height
	var shaft_count: int = params.get("shaft_count", 4)
	var central_radius: float = params.get("central_radius", w * 0.08)
	var satellite_radius: float = params.get("satellite_radius", w * 0.045)
	var orbit_radius: float = params.get("orbit_radius", w * 0.12)
	var segments: int = params.get("segments", 16)
	var material := _make_material(params)

	var cx := w * 0.5

	# Central shaft
	var central := _cylinder_mesh(central_radius, shaft_height, segments, 8,
		material, base_height)
	central.name = "CentralShaft"
	central.position.x = cx
	root.add_child(central)

	# Central shaft caps
	var central_bottom := _disk_mesh(central_radius, base_height, segments, material, false)
	central_bottom.name = "CentralBottom"
	central_bottom.position.x = cx
	root.add_child(central_bottom)

	var central_top := _disk_mesh(central_radius, base_height + shaft_height,
		segments, material, true)
	central_top.name = "CentralTop"
	central_top.position.x = cx
	root.add_child(central_top)

	# Satellite shafts arranged in a circle
	for i in range(shaft_count):
		var angle := TAU * float(i) / float(shaft_count)
		var sx := cos(angle) * orbit_radius
		var sz := sin(angle) * orbit_radius

		var sat := _cylinder_mesh(satellite_radius, shaft_height, segments, 8,
			material, base_height)
		sat.name = "SatelliteShaft_%d" % i
		sat.position = Vector3(cx + sx, 0.0, sz)
		root.add_child(sat)

		# Satellite caps
		var sat_bottom := _disk_mesh(satellite_radius, base_height,
			segments, material, false)
		sat_bottom.name = "SatBottom_%d" % i
		sat_bottom.position = Vector3(cx + sx, 0.0, sz)
		root.add_child(sat_bottom)

		var sat_top := _disk_mesh(satellite_radius, base_height + shaft_height,
			segments, material, true)
		sat_top.name = "SatTop_%d" % i
		sat_top.position = Vector3(cx + sx, 0.0, sz)
		root.add_child(sat_top)

	# Shared base — large enough to encompass all shafts
	var total_radius := orbit_radius + satellite_radius
	var base_root := Node3D.new()
	base_root.name = "Base"
	base_root.position.x = cx
	root.add_child(base_root)
	_add_base(base_root, total_radius, base_height, segments * 2, material)

	# Shared capital
	var cap_root := Node3D.new()
	cap_root.name = "Capital"
	cap_root.position.x = cx
	root.add_child(cap_root)
	_add_capital(cap_root, total_radius, capital_height,
		base_height + shaft_height, segments * 2, material)

	return root


# ==========================================================================
# FACTORY / API
# ==========================================================================

## Create a column by type name. Returns a Node3D subtree.
static func create_column(column_type: String, w: float, h: float,
		params: Dictionary = {}) -> Node3D:
	match column_type:
		"solomonic":
			return solomonic(w, h, params)
		"double_helix":
			return double_helix(w, h, params)
		"straight":
			return straight(w, h, params)
		"profile":
			return profile_column(w, h, params)
		"fluted_twist":
			return fluted_twist(w, h, params)
		"cluster":
			return cluster(w, h, params)
		_:
			push_warning("FacadeProceduralColumns: Unknown type '%s', using straight" % column_type)
			return straight(w, h, params)


## Get all available column type names.
static func get_column_types() -> Array[String]:
	return ["solomonic", "double_helix", "straight", "profile", "fluted_twist", "cluster"]


## Get all available profile preset names for use with profile_column().
static func get_profile_names() -> Array[String]:
	var names: Array[String] = []
	for key in COLUMN_PROFILES.keys():
		names.append(key)
	return names
