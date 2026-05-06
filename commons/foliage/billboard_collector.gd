## BillboardCollector — Walks a MeshData's face metadata for "billboard"
## entries, removes those faces from the solid mesh, and replaces them
## with a MultiMeshInstance3D drawn through one alpha-tested material.
##
## This is the runtime-side payoff for mark_billboard_anchors_op:
##   - One draw call per atlas (vs N draws if rendered as solid stamps)
##   - Alpha-test discards transparent pixels so per-pixel cost is ~30%
##     of a fully-shaded primitive
##   - A 1000-flower meadow ships as a single MultiMesh per species
##
## The op records {atlas, tile, size, color, tilt} per generated quad
## (two faces per quad). We collapse those pairs back into single
## anchor records, group by atlas, build a QuadMesh + MultiMesh per
## group, and remove the billboard faces from the source mesh so they
## don't get rendered twice.
##
## Procedural fallback: if `atlas` is empty or unloadable, a procedural
## petal silhouette texture is used. Same pipeline.
##
## Usage:
##   var n: int = BillboardCollector.collect_into(mg_node, mesh)
##   # n is the number of billboard MultiMeshes installed.
extends RefCounted
class_name BillboardCollector


# Cached procedural textures so multiple flowers share one ImageTexture.
static var _proc_textures: Dictionary = {}


## Walk mesh.face_metadata for billboard entries, install MultiMeshes as
## children of `parent`, and remove the billboard faces from `mesh`.
## Returns the number of distinct atlases (== draw calls added).
static func collect_into(parent: Node3D, mesh: MeshData) -> int:
	if mesh == null or mesh.face_metadata.is_empty():
		return 0
	# Step 1: find every face that has billboard metadata. Pairs of faces
	# (the two triangles of one quad) share the SAME billboard payload, so
	# we collapse them by quad-centroid + size signature.
	var anchors: Array = []  # {atlas, tile, size, color, tilt, basis, origin}
	var bb_face_indices: PackedInt32Array = PackedInt32Array()
	var seen_quads: Dictionary = {}
	for fi in range(mesh.face_metadata.size()):
		var md: Dictionary = mesh.face_metadata[fi]
		if not (md is Dictionary) or not md.has("billboard"):
			continue
		bb_face_indices.append(fi)
		var bb: Dictionary = md["billboard"]
		# Compute the quad's centroid + basis from its triangle's three verts.
		var f := mesh.faces[fi]
		var v0: Vector3 = mesh.vertices[f[0]]
		var v1: Vector3 = mesh.vertices[f[1]]
		var v2: Vector3 = mesh.vertices[f[2]]
		# Quad signature: rounded centroid of the 3-vert triangle. Pairs
		# of triangles from the same quad share three of four vertices,
		# so their centroids are within ~size/3 — round generously.
		var tri_c: Vector3 = (v0 + v1 + v2) / 3.0
		var sig := "%.2f_%.2f_%.2f_%s" % [tri_c.x, tri_c.y, tri_c.z, str(bb.get("atlas", ""))]
		# We want the QUAD's centroid, not the triangle's. Since the quad's
		# two triangles share an edge, averaging both triangles gives the
		# quad centre. We aggregate as we go.
		if seen_quads.has(sig):
			continue  # already recorded the partner triangle
		# Find the partner triangle within ~size of this one.
		# In practice it's the next face index when emitted in order.
		var partner_fi: int = -1
		for fi2 in range(fi + 1, mesh.face_metadata.size()):
			var md2: Dictionary = mesh.face_metadata[fi2]
			if not (md2 is Dictionary) or not md2.has("billboard"):
				break
			var bb2: Dictionary = md2["billboard"]
			if bb.get("atlas", "") != bb2.get("atlas", "") or bb.get("tile", 0) != bb2.get("tile", 0):
				break
			# Confirm shared vertices (partner triangles share two indices).
			var f2 := mesh.faces[fi2]
			var shared: int = 0
			for vi in f:
				for vi2 in f2:
					if vi == vi2:
						shared += 1
						break
			if shared >= 2:
				partner_fi = fi2
				break
			else:
				break
		var quad_centre: Vector3 = tri_c
		var basis_axis: Vector3 = (v1 - v0).cross(v2 - v0)
		if partner_fi >= 0:
			var f2 := mesh.faces[partner_fi]
			var p0: Vector3 = mesh.vertices[f2[0]]
			var p1: Vector3 = mesh.vertices[f2[1]]
			var p2: Vector3 = mesh.vertices[f2[2]]
			quad_centre = (v0 + v1 + v2 + p0 + p1 + p2) / 6.0
			basis_axis += (p1 - p0).cross(p2 - p0)
			seen_quads[sig] = true
			# Mark partner sig too so we don't double-count.
			var partner_tri_c: Vector3 = (p0 + p1 + p2) / 3.0
			var partner_sig := "%.2f_%.2f_%.2f_%s" % [partner_tri_c.x, partner_tri_c.y, partner_tri_c.z, str(bb.get("atlas", ""))]
			seen_quads[partner_sig] = true
		var normal: Vector3 = basis_axis.normalized() if basis_axis.length_squared() > 1e-10 else Vector3.UP

		# Reconstruct the quad's basis from its vertex spread. We pick the
		# longest in-plane edge as the up-axis, perpendicular as the
		# right-axis. Good enough — it matches what the op emitted.
		var verts_list: Array[Vector3] = [v0, v1, v2]
		if partner_fi >= 0:
			var f2 := mesh.faces[partner_fi]
			for vi in f2:
				var p: Vector3 = mesh.vertices[vi]
				if not (p in verts_list):
					verts_list.append(p)
		# Find the longest pair-distance axis as "up" of the billboard.
		var up_axis: Vector3 = Vector3.UP
		var best_d: float = 0.0
		for i in range(verts_list.size()):
			for j in range(i + 1, verts_list.size()):
				var d: float = verts_list[i].distance_squared_to(verts_list[j])
				if d > best_d:
					best_d = d
					up_axis = (verts_list[j] - verts_list[i]).normalized()
		var right_axis: Vector3 = up_axis.cross(normal).normalized()
		var size_v: Vector2 = bb.get("size", Vector2(0.3, 0.4))
		# The op emits with the BASE of the quad at the anchor and the
		# tip at +Y in basis. Pull the centre back so MultiMesh transform
		# treats centre as origin.
		var anchor_origin: Vector3 = quad_centre

		anchors.append({
			"atlas": String(bb.get("atlas", "")),
			"tile": int(bb.get("tile", 0)),
			"size": size_v,
			"color": bb.get("color", Color.WHITE),
			"tilt": float(bb.get("tilt", 0.0)),
			"shader": String(bb.get("shader", "")),
			"dna_params": bb.get("dna_params", {}) if bb.get("dna_params", null) is Dictionary else {},
			"dna_resource": String(bb.get("dna_resource", "")),
			"origin": anchor_origin,
			"up": up_axis,
			"right": right_axis,
			"normal": normal,
		})

	if anchors.is_empty():
		return 0

	# Step 2: group anchors by (atlas, shader, dna_resource).
	var groups: Dictionary = {}
	for a in anchors:
		var key: String = "%s|%s|%s" % [a["atlas"], a.get("shader", ""), a.get("dna_resource", "")]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(a)

	# Step 3: build one MultiMeshInstance3D per group.
	for group_key in groups.keys():
		var group_anchors: Array = groups[group_key]
		var atlas_key: String = String(group_anchors[0]["atlas"])
		var mesh_inst := _build_billboard_multimesh(group_anchors, atlas_key)
		if mesh_inst != null:
			parent.add_child(mesh_inst)

	# Step 4: remove the billboard faces from the source mesh so the
	# main MeshInstance doesn't render the placeholder rectangles.
	if bb_face_indices.size() > 0:
		var sorted := Array(bb_face_indices)
		sorted.sort()
		sorted.reverse()
		mesh.remove_faces(PackedInt32Array(sorted))

	return groups.size()


# Build a MultiMeshInstance3D containing every anchor in `anchors`.
# Each instance gets a per-instance Transform3D + colour. The QuadMesh
# is shared, the material is shared, the draw call count is 1.
static func _build_billboard_multimesh(anchors: Array, atlas_key: String) -> MultiMeshInstance3D:
	if anchors.is_empty():
		return null
	var mm := MultiMesh.new()
	var quad := QuadMesh.new()
	# QuadMesh defaults to size (1,1) facing -Z. We treat the quad's
	# Y-axis as the petal "up" via instance transform (no rotation needed
	# beyond the basis we pass).
	quad.size = Vector2.ONE
	mm.mesh = quad
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = anchors.size()
	for i in range(anchors.size()):
		var a: Dictionary = anchors[i]
		var sz: Vector2 = a["size"]
		var up: Vector3 = a["up"]
		var right: Vector3 = a["right"]
		var normal: Vector3 = a["normal"]
		# Build a basis that scales: width along right, height along up,
		# normal stays unit. Then translate to origin centred at the
		# quad's mid-height (since QuadMesh is centred).
		var b: Basis = Basis(right * sz.x, up * sz.y, normal)
		var mid_origin: Vector3 = a["origin"] + up * (sz.y * 0.5)
		mm.set_instance_transform(i, Transform3D(b, mid_origin))
		mm.set_instance_color(i, a["color"])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "BillboardBatch_%s" % (atlas_key.get_file().get_basename() if atlas_key != "" else "procedural")
	mmi.multimesh = mm

	# Material — alpha-tested with a procedural or loaded texture.
	# Pull shader override + DNA params from the first anchor in the
	# group (all anchors in a group share these by construction).
	var first: Dictionary = anchors[0]
	var shader_override: String = String(first.get("shader", ""))
	var dna_params: Dictionary = first.get("dna_params", {})
	# If the anchor specifies a CritterDNA resource path, load it and
	# overlay its gene values onto dna_params (explicit dna_params keys
	# override the resource — config still wins for fine-tuning).
	var dna_path: String = String(first.get("dna_resource", ""))
	if dna_path != "":
		var loaded: Dictionary = _dna_resource_to_params(dna_path)
		# Anchor's explicit dna_params win when both are set.
		for k in loaded.keys():
			if not dna_params.has(k):
				dna_params[k] = loaded[k]
	if shader_override != "" or dna_params.size() > 0:
		mmi.material_override = _make_billboard_material_with_shader(
			atlas_key,
			shader_override if shader_override != "" else "res://commons/foliage/critter_dna_billboard.gdshader",
			dna_params)
	else:
		mmi.material_override = _make_billboard_material(atlas_key)
	return mmi


# Load a CritterDNA .tres and extract the fields that map to billboard
# shader uniforms. Returns a dict ready for set_shader_parameter.
static func _dna_resource_to_params(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		push_warning("BillboardCollector: dna_resource not found: %s" % path)
		return {}
	var res = load(path)
	if res == null:
		return {}
	var out: Dictionary = {}
	# Color genes — primary/secondary/tertiary map to vec4 uniforms.
	if "primary_color" in res:
		out["primary_color"] = res.get("primary_color")
	if "secondary_color" in res:
		out["secondary_color"] = res.get("secondary_color")
	if "tertiary_color" in res:
		out["wing_color"] = res.get("tertiary_color")  # shader names it wing_color
	# Pattern genes.
	for k in ["pattern_type", "pattern_density", "pattern_scale"]:
		if k in res:
			out[k] = res.get(k)
	# Material genes.
	for k in ["roughness", "metallic", "iridescence"]:
		if k in res:
			out[k] = res.get(k)
	# Animation genes — the CritterDNA's wave_amplitude/frequency are
	# already named to match the billboard shader's wave_* uniforms.
	# (CritterDNA may not have these as @exports; guard accordingly.)
	for k in ["wave_amplitude", "wave_frequency", "wave_intensity"]:
		if k in res:
			out[k] = res.get(k)
	print("[BillboardCollector] loaded DNA from %s: %d uniform(s)" % [path, out.size()])
	return out


# Build a ShaderMaterial from an explicit shader path + per-anchor DNA
# params dict. Used by configs that opt into the rich DNA shader.
static func _make_billboard_material_with_shader(atlas_key: String,
		shader_path: String, dna_params: Dictionary) -> Material:
	var tex: Texture2D = null
	if atlas_key.begins_with("res://") and ResourceLoader.exists(atlas_key):
		tex = load(atlas_key) as Texture2D
	if tex == null:
		tex = _procedural_petal_mask(128)
	if not ResourceLoader.exists(shader_path):
		# Fall back to the default if the override shader is missing.
		return _make_billboard_material(atlas_key)
	var shader: Shader = load(shader_path)
	if shader == null:
		return _make_billboard_material(atlas_key)
	var smat := ShaderMaterial.new()
	smat.shader = shader
	smat.set_shader_parameter("albedo_tex", tex)
	smat.set_shader_parameter("alpha_threshold", 0.5)
	smat.set_shader_parameter("face_camera", 1.0)
	# Sensible wave/wind defaults so configs don't have to set them.
	smat.set_shader_parameter("wave_amplitude", 0.06)
	smat.set_shader_parameter("wave_frequency", 1.5)
	smat.set_shader_parameter("wave_intensity", 1.0)
	# Per-anchor DNA overrides — primary/secondary/tertiary, pattern_*, etc.
	for key in dna_params.keys():
		var val = dna_params[key]
		# Convert array RGB to Color for *_color uniforms.
		if String(key).ends_with("_color") and val is Array:
			var arr: Array = val
			if arr.size() >= 3:
				val = Color(float(arr[0]), float(arr[1]), float(arr[2]),
							float(arr[3]) if arr.size() >= 4 else 1.0)
		smat.set_shader_parameter(String(key), val)
	return smat


## Shader override for individual atlases. If an atlas key is registered
## here, the matching shader is loaded instead of the default. Use this to
## opt a species into the rich CritterDNA-vocabulary shader (patterns,
## iridescence, two-tone fills) rather than the minimal flat shader.
static var _shader_overrides: Dictionary = {}

static func register_shader(atlas_key: String, shader_path: String,
		default_params: Dictionary = {}) -> void:
	_shader_overrides[atlas_key] = {"shader": shader_path, "params": default_params}


static func _make_billboard_material(atlas_key: String) -> Material:
	# Use the camera-facing + wind shader by default. Falls back to a
	# StandardMaterial3D if the shader fails to load (e.g. headless
	# environments without shader support).
	var default_shader := "res://commons/foliage/foliage_billboard.gdshader"
	var shader_path: String = default_shader
	var override_params: Dictionary = {}
	if _shader_overrides.has(atlas_key):
		shader_path = String(_shader_overrides[atlas_key]["shader"])
		override_params = _shader_overrides[atlas_key].get("params", {})
	var tex: Texture2D = null
	if atlas_key.begins_with("res://") and ResourceLoader.exists(atlas_key):
		tex = load(atlas_key) as Texture2D
	if tex == null:
		tex = _procedural_petal_mask(128)
	if ResourceLoader.exists(shader_path):
		var shader: Shader = load(shader_path)
		if shader != null:
			var smat := ShaderMaterial.new()
			smat.shader = shader
			smat.set_shader_parameter("albedo_tex", tex)
			smat.set_shader_parameter("alpha_threshold", 0.5)
			# Default wind via wave_* names (matches critter_dna shader vocab).
			# The simple foliage shader uses wind_amplitude/wind_frequency;
			# we set both so either shader picks up sensible defaults.
			smat.set_shader_parameter("wind_amplitude", 0.06)
			smat.set_shader_parameter("wind_frequency", 1.5)
			smat.set_shader_parameter("wave_amplitude", 0.06)
			smat.set_shader_parameter("wave_frequency", 1.5)
			smat.set_shader_parameter("wave_intensity", 1.0)
			smat.set_shader_parameter("face_camera", 1.0)
			smat.set_shader_parameter("roughness_value", 0.7)
			# Apply registered DNA defaults — primary/secondary/tertiary
			# colors, pattern_*, iridescence, etc.
			for key in override_params.keys():
				smat.set_shader_parameter(String(key), override_params[key])
			return smat
	# Fallback path — same alpha-test behaviour, no wind, no camera-face.
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.0
	mat.roughness = 0.7
	mat.albedo_texture = tex
	return mat


# Procedural petal silhouette — a simple bell-curve shaped alpha mask.
# Width tapers in at top and bottom, peaks in the middle. White RGB so
# vertex_color tinting drives the actual petal colour.
static func _procedural_petal_mask(size: int = 128) -> ImageTexture:
	var key := "petal_%d" % size
	if _proc_textures.has(key):
		return _proc_textures[key]
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		var v: float = float(y) / float(size - 1)
		# Petal width envelope: narrow at base (v=0), bulges to ~0.8 at
		# v=0.55, tapers to a point at v=1.
		var w_env: float = sin(PI * pow(v, 0.7)) * 0.5
		# Rounded base: pull the bottom 10% of v down to zero so the petal
		# has a clean stem.
		if v < 0.08:
			w_env *= v / 0.08
		for x in range(size):
			var u: float = float(x) / float(size - 1) - 0.5  # -0.5..0.5
			var a: float = 0.0
			if absf(u) < w_env:
				# Soft edge — fade alpha near the boundary.
				var edge: float = (w_env - absf(u)) / max(w_env * 0.15, 0.01)
				a = clamp(edge, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_proc_textures[key] = tex
	return tex
