# TopologySpace.gd - Base class for walkable mathematical spaces
extends Node3D
class_name TopologySpace

@export var space_size: Vector2 = Vector2(20, 20)
@export var resolution: int = 100
@export var height_scale: float = 2.0
@export var position_offset: Vector3 = Vector3.ZERO
@export var gravity_point_test := true

## THE SLOT (Palle, 2026-10-31: "parameterise and edge-secure the artifacts so each either slots into the playground
## or stands self-sufficient - start with the walkable surfaces"). A surface told its slot - the receiving place's
## footprint and its depth under the rim (commons/modular/places: place.json "activity") - FITS it: the footprint
## minus a margin, its relief shifted so the lowest point rests on the pool floor and scaled so the highest stays a
## hand under the rim; and is EDGE-SECURED: within edge_band of its perimeter the relief fades to the floor, so the
## surface meets the pool floor flush all round and the rim keeps the walker in. With no slot (slot_depth 0, edge_band
## 0) nothing here changes a placed surface. Subclasses pass their heights through finish_heights().
## THE RIM (Palle, 2026-10-31: "the edge of the floor and walls should in most cases have a rim that is flat, so it
## can be placed in a basin or a wall frame and align with the flat meeting edge"): a band rim_width wide along the
## whole perimeter that lies exactly at the meeting level - the floor plane, or the wall plane - and only inward of
## it, across edge_band, the relief rises. The piece fills its slot (slot_margin 0) and its flat rim meets the basin's
## wall or the frame's edge flush.
@export var rim_width := 0.5      # metres of flat rim at the meeting level, all round
@export var edge_band := 0.0      # metres inward of the rim over which the relief rises from the rim
@export var slot_depth := 0.0     # >0: fitted into a slot this deep
@export var slot_margin := 0.0    # metres kept free between the surface and the slot's wall (the rim does the meeting)
## WALLS TOO (Palle, 2026-10-31: "all there can also be walls"): mounted "wall", the same surface STANDS - its width
## along the node's X, its height up the node's Y from the node's origin (the wall's base line), its relief into the
## room along the node's -Z, fading to the wall plane at its edges. slot_size is then [width, height] and slot_depth
## how far the relief may stand out. The placer sets the node at the wall's base and turns it to face the room.
@export_enum("floor", "wall") var mount := "floor"
## BUMP MAPS (Palle, 2026-10-31: "bump maps?"): the relief's shading as a normal map on the material, from the same
## heights, so the WALKED mesh and its collision may be coarser than the LOOK. collision_step 2 makes the trimesh
## from every second vertex (a quarter of the triangles), 4 a sixteenth; the picture keeps every vertex's slope.
@export var bump_map := false
@export var bump_strength := 1.0
@export_range(1, 8) var collision_step := 1
var _last_heights: Array = []
var fitted := false
const RIM_CLEARANCE := 0.1

func fit_slot(size: Vector2, depth: float, margin := slot_margin, band := 1.0, rim := rim_width) -> void:
	slot_margin = margin
	# a wall keeps its foot on the floor: the margin is taken off its width twice and off its height once, at the top
	space_size = Vector2(size.x - 2.0 * margin, size.y - margin).max(Vector2(1, .5)) if mount == "wall" else (size - Vector2.ONE * 2.0 * margin).max(Vector2(1, 1))
	var least := minf(space_size.x, space_size.y)
	rim_width = clampf(rim, 0.0, least / 4.0);edge_band = clampf(band, 0.0, least / 4.0)
	slot_depth = depth;fitted = true;gravity_point_test = false
	_stand()

## The body stands up for a wall (local z becomes up, local relief becomes -Z) and lies flat for a floor.
func _stand() -> void:
	if static_body == null:return
	static_body.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0, space_size.y / 2.0, 0)) if mount == "wall" else Transform3D.IDENTITY

## 0 on the rim (the flat meeting edge), rising smoothly across the band inward of it, 1 in the interior.
func edge_factor(wx: float, wz: float) -> float:
	if edge_band <= 0.0 and rim_width <= 0.0:return 1.0
	var d := minf(space_size.x / 2.0 - absf(wx), space_size.y / 2.0 - absf(wz)) - rim_width
	if d <= 0.0:return 0.0
	if edge_band <= 0.0:return 1.0
	return smoothstep(0.0, 1.0, clampf(d / edge_band, 0.0, 1.0))

## The heights as the slot wants them: the band fades toward the field's lowest value (so the perimeter and the
## floor meet), then the whole field is lifted onto the floor and scaled under the rim. No slot: the heights as given.
## Called by create_mesh_from_heights for EVERY surface of the family, so a subclass needs no line of its own; with
## no slot and no rim it returns the heights untouched.
func finish_heights(heights: Array) -> Array:
	if (edge_band <= 0.0 and rim_width <= 0.0 and slot_depth <= 0.0) or not (fitted or slot_depth > 0.0):return heights
	var out: Array = heights.duplicate()
	var lo := INF;var hi := -INF
	for h in out:lo = minf(lo, float(h));hi = maxf(hi, float(h))
	if edge_band > 0.0 or rim_width > 0.0:
		for z in range(resolution + 1):
			for x in range(resolution + 1):
				var wx := (x / float(resolution)) * space_size.x - space_size.x / 2.0
				var wz := (z / float(resolution)) * space_size.y - space_size.y / 2.0
				var i := z * (resolution + 1) + x
				out[i] = lerpf(lo, float(out[i]), edge_factor(wx, wz))
	if slot_depth > 0.0:
		var room := maxf(slot_depth - RIM_CLEARANCE, 0.05);var k := 1.0 if hi - lo <= room else room / (hi - lo)
		for i in out.size():out[i] = (float(out[i]) - lo) * k
	return out

## The slot and the base's own numbers from a config (the hand's / the place's apply_grid_config keys). True if changed.
func apply_slot_config(config: Dictionary) -> bool:
	var changed := false
	if config.has("mount"):mount = "wall" if str(config.mount) == "wall" else "floor";changed = true
	if config.has("slot_size") and config.slot_size is Array and (config.slot_size as Array).size() == 2:
		var sz := Vector2(float(config.slot_size[0]), float(config.slot_size[1]))
		fit_slot(sz, float(config.get("slot_depth", slot_depth)), float(config.get("slot_margin", slot_margin)), float(config.get("edge_band", 1.0)), float(config.get("rim_width", rim_width)));changed = true
	else:
		if config.has("edge_band"):edge_band = maxf(float(config.edge_band), 0.0);changed = true
		if config.has("rim_width"):rim_width = maxf(float(config.rim_width), 0.0);changed = true
		if config.has("slot_depth"):slot_depth = maxf(float(config.slot_depth), 0.0);changed = true
	if config.has("height_scale"):height_scale = float(config.height_scale);changed = true
	if config.has("resolution"):resolution = clampi(int(config.resolution), 4, 200);changed = true
	if config.has("bump_map"):bump_map = str(config.bump_map) in ["true", "True", "1"] if not config.bump_map is bool else bool(config.bump_map);changed = true
	if config.has("bump_strength"):bump_strength = float(config.bump_strength);changed = true
	if config.has("collision_step"):collision_step = clampi(int(config.collision_step), 1, 8);changed = true
	if changed:_stand()
	return changed

## The config_* metas a placer leaves on the node before it enters the tree.
func meta_config() -> Dictionary:
	var cfg := {}
	for m in get_meta_list():
		if str(m).begins_with("config_"):cfg[str(m).trim_prefix("config_")] = get_meta(m)
	return cfg

## The default: the slot and the base numbers, then a fresh surface. Subclasses with knobs of their own extend this.
func apply_grid_config(config: Dictionary) -> void:
	if apply_slot_config(config) and mesh_instance != null:generate_space()

var static_body: StaticBody3D
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

func _ready():
	apply_slot_config(meta_config())
	setup_topology_space()
	_stand()
	generate_space()
	if gravity_point_test:
		var probe := preload("res://commons/artifacts/surface_ball_test/surface_ball_test.tscn").instantiate()
		probe.name = "SurfaceBallTest"
		probe.auto_trigger = true
		add_child(probe)

func setup_topology_space():
	# Create or find StaticBody3D
	static_body = get_node_or_null("StaticBody3D")
	if not static_body:
		static_body = StaticBody3D.new()
		static_body.name = "StaticBody3D"
		add_child(static_body)
	
	# Find or create MeshInstance3D under StaticBody3D
	mesh_instance = static_body.get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		static_body.add_child(mesh_instance)
	
	# Find or create CollisionShape3D under StaticBody3D
	collision_shape = static_body.get_node_or_null("CollisionShape3D")
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		static_body.add_child(collision_shape)

func generate_space():
	# Override in child classes
	pass

func create_mesh_from_heights(raw_heights: Array) -> ArrayMesh:
	var heights: Array = finish_heights(raw_heights)   # the slot's floor, rim and band - once, here, for the whole family
	_last_heights = heights
	if bump_map:call_deferred("_apply_bump")
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Generate vertices and UVs
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var world_pos = Vector3(
				(x / float(resolution)) * space_size.x - space_size.x/2 + position_offset.x,
				heights[z * (resolution + 1) + x] + position_offset.y,
				(z / float(resolution)) * space_size.y - space_size.y/2 + position_offset.z
			)
			vertices.append(world_pos)
			uvs.append(Vector2(x / float(resolution), z / float(resolution)))
	
	# Generate indices for triangles (CORRECT WINDING ORDER)
	for z in range(resolution):
		for x in range(resolution):
			var i = z * (resolution + 1) + x
			
			# First triangle (counter-clockwise when viewed from above)
			indices.append(i)
			indices.append(i + 1)
			indices.append(i + resolution + 1)
			
			# Second triangle (counter-clockwise when viewed from above)
			indices.append(i + 1)
			indices.append(i + resolution + 2)
			indices.append(i + resolution + 1)
	
	# Calculate proper normals using cross product
	normals.resize(vertices.size())
	# Initialize all normals to zero
	for i in range(normals.size()):
		normals[i] = Vector3.ZERO
	
	# Calculate face normals and accumulate to vertex normals
	for i in range(0, indices.size(), 3):
		var i1 = indices[i]
		var i2 = indices[i + 1]
		var i3 = indices[i + 2]
		
		var v1 = vertices[i1]
		var v2 = vertices[i2]
		var v3 = vertices[i3]
		
		# Calculate face normal (cross product)
		var edge1 = v2 - v1
		var edge2 = v3 - v1
		var face_normal = edge1.cross(edge2).normalized()
		
		# Accumulate to vertex normals
		normals[i1] += face_normal
		normals[i2] += face_normal
		normals[i3] += face_normal
	
	# Normalize all vertex normals
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
		# Ensure normals point upward (flip if pointing down)
		if normals[i].y < 0:
			normals[i] = -normals[i]
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func create_collision_from_mesh(mesh: ArrayMesh):
	# Use Godot's built-in mesh collision creation
	# Option 1: Trimesh collision (most accurate, more expensive)
	# coarser than the look when collision_step > 1: the trimesh of every step-th vertex of the last heights
	var source: ArrayMesh = _coarse_mesh(collision_step) if collision_step > 1 and not _last_heights.is_empty() else mesh
	var trimesh_shape = source.create_trimesh_shape()
	collision_shape.shape = trimesh_shape
	
	# Option 2: Convex collision (less accurate, much faster)
	# var convex_shape = mesh.create_convex_shape()
	# collision_shape.shape = convex_shape

## The last heights at every step-th vertex, as a mesh of their own (for a coarse collision under a fine look).
func _coarse_mesh(step: int) -> ArrayMesh:
	var n := int(resolution / step)
	var verts := PackedVector3Array();var idx := PackedInt32Array()
	for z in range(n + 1):
		for x in range(n + 1):
			var sx: int = mini(x * step, resolution);var sz: int = mini(z * step, resolution)
			verts.append(Vector3((sx / float(resolution)) * space_size.x - space_size.x / 2 + position_offset.x, float(_last_heights[sz * (resolution + 1) + sx]) + position_offset.y, (sz / float(resolution)) * space_size.y - space_size.y / 2 + position_offset.z))
	for z in range(n):
		for x in range(n):
			var i := z * (n + 1) + x
			idx.append(i);idx.append(i + 1);idx.append(i + n + 1);idx.append(i + 1);idx.append(i + n + 2);idx.append(i + n + 1)
	var arrays := [];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX] = verts;arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new();m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays);return m

## The normal map of the last heights, onto the material the subclass set (deferred: subclasses assign their
## material after the mesh). Tangent space of the flat grid: x right, z down the image, y out.
func _apply_bump() -> void:
	if mesh_instance == null or _last_heights.is_empty():return
	var mat := mesh_instance.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new();mesh_instance.material_override = mat
	var n := resolution + 1;var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var dx := space_size.x / float(resolution);var dz := space_size.y / float(resolution)
	for z in range(n):
		for x in range(n):
			var l: float = float(_last_heights[z * n + maxi(x - 1, 0)]);var r: float = float(_last_heights[z * n + mini(x + 1, n - 1)])
			var u: float = float(_last_heights[maxi(z - 1, 0) * n + x]);var d: float = float(_last_heights[mini(z + 1, n - 1) * n + x])
			var nrm := Vector3(-(r - l) / (2.0 * dx) * bump_strength, 1.0, -(d - u) / (2.0 * dz) * bump_strength).normalized()
			img.set_pixel(x, z, Color(nrm.x * .5 + .5, nrm.z * .5 + .5, nrm.y * .5 + .5))   # OpenGL-style: green is the image's down axis
	mat.normal_enabled = true;mat.normal_texture = ImageTexture.create_from_image(img);mat.normal_scale = 1.0

func create_collision_single_convex(mesh: ArrayMesh):
	# Creates single convex hull - good for simple shapes
	var convex_shape = mesh.create_convex_shape()
	collision_shape.shape = convex_shape

func create_collision_multiple_convex(mesh: ArrayMesh):
	# Creates multiple convex shapes - better approximation
	var shapes = mesh.convex_decompose()
	if shapes.size() > 0:
		# Use first shape, or could create multiple CollisionShape3D nodes
		collision_shape.shape = shapes[0]

func create_outline_collision(mesh: ArrayMesh):
	# Creates collision from mesh outline - useful for 2D-like surfaces
	var outline_shape = mesh.create_outline(0.1)  # 0.1 = margin
	if outline_shape:
		collision_shape.shape = outline_shape

# ── Shared Shader Utilities ──────────────────────────────────

func apply_height_shader(
	color_low: Color = Color(0.15, 0.12, 0.2),
	color_mid: Color = Color(0.4, 0.45, 0.5),
	color_high: Color = Color(0.9, 0.85, 0.75),
	h_min: float = -2.0,
	h_max: float = 4.0,
	contours: bool = false,
	contour_spacing: float = 0.5
) -> ShaderMaterial:
	"""Apply the shared terrain_height_color shader to this space.
	   Returns the ShaderMaterial for further customization."""
	var shader = load("res://commons/context/walkgrids/terrain_height_color.gdshader")
	if shader == null:
		push_warning("TopologySpace: Could not load terrain_height_color.gdshader")
		return null
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("color_low", Vector3(color_low.r, color_low.g, color_low.b))
	mat.set_shader_parameter("color_mid", Vector3(color_mid.r, color_mid.g, color_mid.b))
	mat.set_shader_parameter("color_high", Vector3(color_high.r, color_high.g, color_high.b))
	mat.set_shader_parameter("height_min", h_min)
	mat.set_shader_parameter("height_max", h_max)
	mat.set_shader_parameter("show_contours", contours)
	mat.set_shader_parameter("contour_spacing", contour_spacing)
	mesh_instance.material_override = mat
	return mat

func apply_standard_material(
	color: Color = Color(0.5, 0.5, 0.5),
	roughness_val: float = 0.7,
	metallic_val: float = 0.1,
	emission_color: Color = Color.BLACK,
	emission_strength: float = 0.0
) -> StandardMaterial3D:
	"""Apply a StandardMaterial3D with common settings.
	   Returns the material for further customization."""
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness_val
	mat.metallic = metallic_val
	if emission_strength > 0.0:
		mat.emission_enabled = true
		mat.emission = emission_color
		mat.emission_energy_multiplier = emission_strength
	mesh_instance.material_override = mat
	return mat

func get_height_at_world_position(world_pos: Vector3) -> float:
	"""Sample the terrain height at a world XZ position (approximate).
	   Returns 0.0 if position is outside the space bounds."""
	var local = world_pos - global_position
	var u = (local.x + space_size.x / 2.0) / space_size.x
	var v = (local.z + space_size.y / 2.0) / space_size.y
	if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
		return 0.0
	# Bilinear sample from mesh vertices
	var gx = u * float(resolution)
	var gz = v * float(resolution)
	var ix = int(gx)
	var iz = int(gz)
	ix = clampi(ix, 0, resolution - 1)
	iz = clampi(iz, 0, resolution - 1)
	# Read from mesh if available
	if mesh_instance and mesh_instance.mesh:
		var arrays = mesh_instance.mesh.surface_get_arrays(0)
		if arrays and arrays[Mesh.ARRAY_VERTEX]:
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var gs = resolution + 1
			var idx = iz * gs + ix
			if idx < verts.size():
				return verts[idx].y
	return 0.0
