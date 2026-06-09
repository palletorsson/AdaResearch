# @identity
# essence: a small triangular cloth pennant — a screen-printed promo handkerchief / old milk-triangle packet — draped on the floor with one corner lifted and folded, printed with a repeating field of red warning triangles and blue logo blocks
# desire: to be a soft, humble, hand-printed object in a hard procedural world — the warmth of woven cream fabric against the geometry of the lab
# critical_parameter: fold_amount — how far the lifted corner peels up off the floor; at 0 it lies flat, at 1 it stands like a sail
# triggers: _ready() builds one ArrayMesh triangle + one painted ImageTexture; apply_grid_config re-skins size/fold/seed
# emerges: print_seed jitters the printed field so no two cloths read identically; the sag in the interior verts gives the fabric weight
# needs: VR sitting on floor [has — origin at base]; grabbing [missing]; apply_grid_config [has]
# relationships: a lab_prop scatter object; pairs with other surreal-lab cloth/print props
# truth: a printed warning on soft cloth is a warning that cannot hurt you — the triangle made gentle

extends Node3D
class_name MilkTriangle

## Milk Triangle — a procedural draped triangular cloth pennant.
##
## One ArrayMesh triangle (subdivided, sagging, one corner lifted/folded) skinned
## with a procedural screen-print texture: cream woven background + a repeating
## field of red warning triangles and blue rounded logo/text blocks.
## Origin sits at the base so it rests on the floor.

# --- Configuration knobs ---

@export var size: float = 0.7              ## Edge length of the cloth in meters (~0.6-0.8)
@export var fold_amount: float = 0.6       ## 0 = flat on floor, 1 = lifted corner peels fully up
@export var print_seed: int = 7            ## Deterministic jitter of the printed field
@export var subdivisions: int = 8          ## Mesh resolution per edge (drape detail)
@export var sag_amount: float = 0.04       ## How much the interior of the cloth sags down

# --- Internal ---

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = print_seed
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("size"):
		size = float(config_data["size"])
	if config_data.has("fold_amount"):
		fold_amount = clampf(float(config_data["fold_amount"]), 0.0, 1.0)
	if config_data.has("print_seed"):
		print_seed = int(config_data["print_seed"])
	if config_data.has("subdivisions"):
		subdivisions = maxi(2, int(config_data["subdivisions"]))
	if config_data.has("sag_amount"):
		sag_amount = float(config_data["sag_amount"])
	# Rebuild with new config
	if _rng == null:
		_rng = RandomNumberGenerator.new()
	_rng.seed = print_seed
	_build()


func _build() -> void:
	# Clear any prior build (so apply_grid_config can re-run safely)
	if _mesh_instance != null and is_instance_valid(_mesh_instance):
		_mesh_instance.queue_free()
		_mesh_instance = null

	_material = _make_material()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "ClothMesh"
	_mesh_instance.mesh = _build_cloth_mesh()
	_mesh_instance.material_override = _material
	add_child(_mesh_instance)


# --- Geometry --------------------------------------------------------------

func _build_cloth_mesh() -> ArrayMesh:
	# Barycentric triangulation of a triangle with corners A, B, C in the XZ
	# plane. A is the "lifted" corner. We subdivide into rows and displace each
	# vertex in Y to give sag (interior droops) + fold (corner A peels up).
	#
	# Origin is the centroid projected to floor (y=0), so the cloth rests on the
	# ground with the base flat.

	var n: int = maxi(2, subdivisions)
	var s: float = maxf(0.1, size)
	var h: float = s * 0.8660254              # height of equilateral triangle

	# Flat-plane triangle corners (centroid-ish origin, base on floor)
	# A = lifted apex (front), B = back-left, C = back-right
	var a: Vector3 = Vector3(0.0, 0.0, -h * 0.6667)
	var b: Vector3 = Vector3(-s * 0.5, 0.0, h * 0.3333)
	var c: Vector3 = Vector3(s * 0.5, 0.0, h * 0.3333)

	var verts: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()

	# Build vertices row by row using barycentric interpolation.
	# Row i goes from i=0 (at corner A) to i=n (along edge B-C).
	# index_of[i][j] maps grid position to a flat vertex index.
	var index_of: Array = []

	for i in range(n + 1):
		var row: Array = []
		# Number of verts in this row = i + 1
		for j in range(i + 1):
			# Barycentric weights: u toward A, v toward B, w toward C
			var u: float = 1.0 - (float(i) / float(n))
			var bc_t: float = 0.0
			if i > 0:
				bc_t = float(j) / float(i)
			var v: float = (1.0 - u) * (1.0 - bc_t)
			var w: float = (1.0 - u) * bc_t

			var p: Vector3 = a * u + b * v + c * w

			# Sag: droop interior of cloth. Strength peaks where all three
			# weights are balanced (center), zero at edges/corners.
			var edge_factor: float = minf(u, minf(v, w)) * 3.0
			edge_factor = clampf(edge_factor, 0.0, 1.0)
			var sag: float = sag_amount * sin(edge_factor * PI) * -1.0
			# Tiny woven ripple for fabric feel (deterministic, no randf)
			var ripple: float = sin(p.x * 22.0 + p.z * 17.0) * 0.004 * edge_factor

			# Fold: lift corner A. The closer to A (u high), the more lift.
			# Use a curved profile so the corner peels rather than hinging flat.
			var lift_w: float = clampf((u - 0.55) / 0.45, 0.0, 1.0)
			var lift: float = lift_w * lift_w * fold_amount * (s * 0.55)
			# Pull the lifted corner back over the cloth (a fold, not a flap)
			var fold_pull: float = lift_w * lift_w * fold_amount * (h * 0.35)

			p.y += sag + ripple + lift
			p.z += fold_pull

			verts.push_back(p)
			# UV: u toward A maps to triangle apex in texture space.
			uvs.push_back(Vector2(0.5 + (w - v) * 0.5, 1.0 - u))
			normals.push_back(Vector3.UP)
			row.push_back(verts.size() - 1)
		index_of.push_back(row)

	# Stitch triangles between consecutive rows.
	for i in range(1, n + 1):
		var prev: Array = index_of[i - 1]
		var curr: Array = index_of[i]
		for j in range(i):
			# Upward triangle
			indices.push_back(prev[j])
			indices.push_back(curr[j])
			indices.push_back(curr[j + 1])
			# Downward triangle (only when there is room)
			if j < i - 1:
				indices.push_back(prev[j])
				indices.push_back(curr[j + 1])
				indices.push_back(prev[j + 1])

	# Recompute smooth normals from faces for nicer shading.
	_recompute_normals(verts, indices, normals)

	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = indices

	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


func _recompute_normals(verts: PackedVector3Array, indices: PackedInt32Array, normals: PackedVector3Array) -> void:
	# Accumulate face normals onto vertices, then normalize.
	for i in range(normals.size()):
		normals[i] = Vector3.ZERO

	var tri: int = 0
	while tri < indices.size() - 2:
		var i0: int = indices[tri]
		var i1: int = indices[tri + 1]
		var i2: int = indices[tri + 2]
		var e1: Vector3 = verts[i1] - verts[i0]
		var e2: Vector3 = verts[i2] - verts[i0]
		var fn: Vector3 = e1.cross(e2)
		normals[i0] += fn
		normals[i1] += fn
		normals[i2] += fn
		tri += 3

	for i in range(normals.size()):
		if normals[i].length() > 0.0001:
			normals[i] = normals[i].normalized()
		else:
			normals[i] = Vector3.UP


# --- Material + procedural print ------------------------------------------

func _make_material() -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_texture = _build_print_texture()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED   # double-sided (drape shows both faces)
	mat.roughness = 0.85
	mat.metallic = 0.0
	mat.specular = 0.15
	return mat


func _build_print_texture() -> ImageTexture:
	var tex_w: int = 256
	var tex_h: int = 256
	var img: Image = Image.create(tex_w, tex_h, false, Image.FORMAT_RGBA8)

	# Colors
	var cream_a: Color = Color(0.93, 0.90, 0.80)
	var cream_b: Color = Color(0.88, 0.84, 0.72)
	var thread: Color = Color(0.82, 0.78, 0.66)
	var red: Color = Color(0.82, 0.18, 0.14)
	var blue: Color = Color(0.13, 0.22, 0.52)
	var bar: Color = Color(0.78, 0.83, 0.95)

	# 1. Woven cream background — alternating warp/weft threads.
	for py in range(tex_h):
		for px in range(tex_w):
			var weave: int = ((px / 2) + (py / 2)) % 2
			var base: Color = cream_a if weave == 0 else cream_b
			# thin thread lines every 8px
			if px % 8 == 0 or py % 8 == 0:
				base = base.lerp(thread, 0.4)
			img.set_pixel(px, py, base)

	# 2. Repeating print field — a grid of cells, each holding either a red
	#    warning triangle or a blue logo block, jittered by print_seed.
	var cells: int = 4
	var cell: int = tex_w / cells
	for cy in range(cells):
		for cx in range(cells):
			var ox: int = cx * cell + int(_rng.randf_range(-2.0, 2.0))
			var oy: int = cy * cell + int(_rng.randf_range(-2.0, 2.0))
			# Alternate motif in a checker so reds and blues interleave.
			if (cx + cy) % 2 == 0:
				_draw_warning_triangle(img, ox, oy, cell, red)
			else:
				_draw_logo_block(img, ox, oy, cell, blue, bar)

	return ImageTexture.create_from_image(img)


func _draw_warning_triangle(img: Image, ox: int, oy: int, cell: int, col: Color) -> void:
	# A filled upward triangle centered in the cell, leaving a margin.
	var margin: int = int(float(cell) * 0.22)
	var tw: int = cell - margin * 2          # triangle base width
	if tw <= 1:
		return
	var apex_x: float = float(ox) + float(cell) * 0.5
	var base_y: int = oy + cell - margin
	var top_y: int = oy + margin
	var height: int = base_y - top_y
	if height <= 0:
		return
	for ly in range(height + 1):
		var py: int = top_y + ly
		if py < 0 or py >= img.get_height():
			continue
		# Half-width grows linearly from apex (ly=0) to base (ly=height)
		var hw: float = (float(ly) / float(height)) * (float(tw) * 0.5)
		var x_start: int = int(apex_x - hw)
		var x_end: int = int(apex_x + hw)
		for px in range(x_start, x_end + 1):
			if px < 0 or px >= img.get_width():
				continue
			# Leave a thin inner cut-out near the top for a "!" warning glyph feel
			img.set_pixel(px, py, col)


func _draw_logo_block(img: Image, ox: int, oy: int, cell: int, col: Color, bar_col: Color) -> void:
	# A rounded blue rectangle with two light horizontal bars (faux logo/text).
	var margin: int = int(float(cell) * 0.18)
	var x0: int = ox + margin
	var y0: int = oy + margin
	var x1: int = ox + cell - margin
	var y1: int = oy + cell - margin
	var radius: int = int(float(cell) * 0.14)
	for py in range(y0, y1):
		if py < 0 or py >= img.get_height():
			continue
		for px in range(x0, x1):
			if px < 0 or px >= img.get_width():
				continue
			# Rounded-corner test
			if _outside_rounded(px, py, x0, y0, x1, y1, radius):
				continue
			img.set_pixel(px, py, col)

	# Two light bars inside (faux text lines)
	var inner_w: int = x1 - x0
	var bar_h: int = maxi(1, int(float(cell) * 0.08))
	var bar1_y: int = y0 + int(float(y1 - y0) * 0.35)
	var bar2_y: int = y0 + int(float(y1 - y0) * 0.60)
	_fill_bar(img, x0 + int(float(inner_w) * 0.2), bar1_y, x1 - int(float(inner_w) * 0.2), bar1_y + bar_h, bar_col)
	_fill_bar(img, x0 + int(float(inner_w) * 0.2), bar2_y, x1 - int(float(inner_w) * 0.35), bar2_y + bar_h, bar_col)


func _outside_rounded(px: int, py: int, x0: int, y0: int, x1: int, y1: int, radius: int) -> bool:
	# Returns true if the pixel lies in a clipped corner of a rounded rect.
	var cx: int = px
	var cy: int = py
	var corner: Vector2 = Vector2.ZERO
	var in_corner: bool = false
	if cx < x0 + radius and cy < y0 + radius:
		corner = Vector2(float(x0 + radius), float(y0 + radius)); in_corner = true
	elif cx > x1 - radius and cy < y0 + radius:
		corner = Vector2(float(x1 - radius), float(y0 + radius)); in_corner = true
	elif cx < x0 + radius and cy > y1 - radius:
		corner = Vector2(float(x0 + radius), float(y1 - radius)); in_corner = true
	elif cx > x1 - radius and cy > y1 - radius:
		corner = Vector2(float(x1 - radius), float(y1 - radius)); in_corner = true
	if not in_corner:
		return false
	return Vector2(float(cx), float(cy)).distance_to(corner) > float(radius)


func _fill_bar(img: Image, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	for py in range(y0, y1):
		if py < 0 or py >= img.get_height():
			continue
		for px in range(x0, x1):
			if px < 0 or px >= img.get_width():
				continue
			img.set_pixel(px, py, col)
