extends RefCounted
## Mesh Grammar recipe for a closed shell with a recessed luminous seam.

const Extrude := preload("res://commons/mesh_grammar/operations/extrude_face_op.gd")
const Subdivide := preload("res://commons/mesh_grammar/operations/smooth_subdivide_op.gd")
const RECIPES_PATH := "res://commons/hazards/electrical_mine/dna_recipes.json"

static var shell_mesh: ArrayMesh
static var dna_recipes: Dictionary
static var dna_meshes: Dictionary
static var dna_radii: Dictionary

static func recipe(id: String) -> Dictionary:
	if id.is_empty(): return {}
	if dna_recipes.is_empty():
		var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(RECIPES_PATH))
		if loaded is Dictionary: dna_recipes = loaded
	return dna_recipes.get(id, {})

static func mesh_for(id: String) -> ArrayMesh:
	if not dna_meshes.has(id):
		var mesh := build_recipe(recipe(id))
		var radius := 0.0
		for surface in mesh.get_surface_count():
			var vertices: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				radius = maxf(radius, vertex.length())
		dna_meshes[id] = mesh
		dna_radii[id] = radius
	return dna_meshes[id]

static func radius_for(id: String) -> float:
	return dna_radii[id]

static func make() -> ArrayMesh:
	if shell_mesh != null:
		return shell_mesh

	# A lathe seed gives us connected rings. The inner rings sit below the
	# two metal lips, so the glow is on the floor of a channel in the shell.
	var profile := PackedVector2Array([
		Vector2(0, .426), Vector2(.105, .413), Vector2(.214, .367),
		Vector2(.305, .3), Vector2(.374, .207), Vector2(.405, .126),
		Vector2(.416, .076), Vector2(.424, .050), Vector2(.422, .032),
		Vector2(.389, .016), Vector2(.389, -.016), Vector2(.422, -.032),
		Vector2(.424, -.050), Vector2(.416, -.076), Vector2(.405, -.126),
		Vector2(.374, -.207), Vector2(.305, -.3), Vector2(.214, -.367),
		Vector2(.105, -.413), Vector2(0, -.426),
	])
	var seed := MeshData.create_lathe(profile, 24)
	for i in seed.face_count():
		var centre := seed.get_face_centroid(i)
		if absf(centre.y) < .012:
			seed.tag_face(i, "surface_charge")
		elif absf(centre.y) > .090 and absf(centre.y) < .112:
			# Choose one face per sector to emboss repeating teeth on both sides.
			var sector := int(round(atan2(centre.z, centre.x) * 24 / TAU))
			if posmod(sector, 3) == 0:
				seed.tag_face(i, "teeth")

	var grammar := MeshGrammar.new()
	grammar.set_seed(seed)
	grammar.add_rule(Extrude.new(MeshSelector.by_tag("teeth"), {
		"distance": .027, "scale": .78, "min_area": .0001,
	}))
	# One Loop pass rounds the chamfer and tooth edges and preserves the tags.
	grammar.add_rule(Subdivide.new(MeshSelector.all_faces(), {"passes": 1}))
	var mesh_data := grammar.apply_step()
	var surfaces := mesh_data.to_multi_surface_mesh("surface_", {"double_sided": false})
	shell_mesh = surfaces.mesh
	for i in surfaces.surface_names.size():
		shell_mesh.surface_set_name(i, surfaces.surface_names[i])
	return shell_mesh

static func build_recipe(spec: Dictionary) -> ArrayMesh:
	var profile := PackedVector2Array()
	for row in spec.profile:
		profile.append(Vector2(float(row[1]), float(row[0])))
	var seed := MeshData.create_lathe(profile, int(spec.segments))
	for i in seed.vertices.size():
		var vertex := seed.vertices[i]
		var radius := Vector2(vertex.x, vertex.z).length()
		var angle := atan2(vertex.z, vertex.x)
		var envelope := pow(clampf(radius / .42, 0, 1), 1.4)
		var flutes := 1.0 + float(spec.flute) * cos(angle * float(spec.flute_count)) * envelope
		vertex.x *= flutes
		vertex.z *= flutes
		vertex.y += float(spec.wave) * sin(angle * float(spec.wave_count)) * envelope
		seed.vertices[i] = vertex

	# Lathe face rings preserve their order through the deformation. Tag the
	# channel floor and the shoulders before extruding and subdividing.
	var face := 0
	var segments := int(spec.segments)
	var seams := PackedInt32Array(spec.seams)
	var trim := PackedInt32Array(spec.trim_rings)
	var teeth := PackedInt32Array(spec.tooth_rings)
	for ring in range(profile.size() - 1):
		var faces_per_sector := 1 if ring == 0 or ring == profile.size() - 2 else 2
		for sector in segments:
			for triangle in faces_per_sector:
				var stagger := sector if ring < profile.size() / 2.0 else sector + int(spec.stagger)
				if ring in seams and posmod(sector, int(spec.segment_cycle)) < int(spec.segment_lit):
					seed.tag_face(face, "surface_charge")
				elif ring in trim:
					seed.tag_face(face, "surface_trim")
				elif ring in teeth and triangle == 0 and posmod(stagger, int(spec.tooth_step)) == 0:
					seed.tag_face(face, "tooth")
				face += 1
	var grammar := MeshGrammar.new()
	grammar.set_seed(seed)
	grammar.add_rule(Extrude.new(MeshSelector.by_tag("tooth"), {
		"distance": float(spec.extrusion), "scale": float(spec.taper),
		"min_area": .00003, "top_tag": "surface_trim",
	}))
	grammar.add_rule(Subdivide.new(MeshSelector.all_faces(), {"passes": int(spec.get("subdivision_passes", 1))}))
	var shaped := grammar.apply_step()
	assert(shaped.get_boundary_edges().is_empty())
	var result := shaped.to_multi_surface_mesh("surface_", {"double_sided": false})
	var mesh: ArrayMesh = result.mesh
	for i in result.surface_names.size():
		mesh.surface_set_name(i, result.surface_names[i])
	return mesh
