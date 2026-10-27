extends Node3D

# @identity
# essence: 98 procedural Albers "Homage to the Square" paintings — nested squares with golden-ratio hue walks and inset_ratio^i scaling
# desire: to stand before a gallery wall and see how color relationships change when squares nest inside squares — Albers' life work, proceduralized
# critical_parameter: inset_ratio — controls how quickly inner squares shrink; at 0.78 the nesting feels balanced, at extremes it collapses or barely nests
# triggers: palette_seed + index * 31 generates deterministic but varied palettes per canvas; no runtime interaction
# emerges: the vertical_bias shifts inner squares downward, creating a gravity effect that makes the paintings feel grounded without explicit composition rules
# needs: spot lighting [has]; framed canvases [has]; VR walkup viewing [has]; glass media — relief slabs and nested cubes, multiply filters solved in linear light over a light table (medium axis) [has]; interactive palette tuning [missing]
# relationships: standalone Albers study; contrasts with color_constellation_office (color as light vs color as paint); feeds into color theory understanding
# truth: a square inside a square is not decoration — it is an experiment in how context changes the perception of every color it touches

@export var total_canvases: int = 98
@export var columns: int = 14
@export var rows: int = 7

@export var canvas_size: float = 0.38
@export var canvas_depth: float = 0.04
@export var canvas_color: Color = Color(0.98, 0.98, 0.97, 1.0)

@export var frame_thickness: float = 0.02
@export var frame_depth: float = 0.03
@export var frame_color: Color = Color(0.08, 0.08, 0.09, 1.0)

@export var show_wall: bool = true
@export var show_floor: bool = false
@export var show_frames: bool = true
@export var show_canvas: bool = true

@export var gap: float = 0.08
@export var wall_margin: float = 0.7
@export var wall_depth: float = 0.12
@export var wall_color: Color = Color(0.97, 0.97, 0.97, 1.0)

@export var squares_per_canvas: int = 5
@export var inset_ratio: float = 0.78
@export var border_ratio: float = 0.05
@export var vertical_bias: float = -0.06

@export_category("Lighting")
@export var ambient_energy: float = 0.6
@export var spot_count: int = 4
@export var spot_energy: float = 6.0
@export var spot_angle: float = 55.0
@export var spot_range: float = 10.0
@export var spot_height: float = 3.8
@export var spot_distance: float = 2.4
@export var spot_color: Color = Color(1.0, 0.98, 0.92, 1.0)

@export_category("Palette")
@export var palette_seed: int = 1337
@export_range(0.0, 1.0, 0.01) var palette_saturation_min: float = 0.35
@export_range(0.0, 1.0, 0.01) var palette_saturation_max: float = 0.9
@export_range(0.0, 1.0, 0.01) var palette_value_min: float = 0.6
@export_range(0.0, 1.0, 0.01) var palette_value_max: float = 0.98

@export_category("Medium")
## What the homages are made of (doc/colour/albers_glass/SPEC.md).
##   paint   today's wall, byte-identical: opaque tube colour, nothing mixes
##   relief  five thin filter slabs per homage, stepped 3 cm apart over a white light table
##   cubes   five nested glass cubes per homage (85% of the painted square, the outer
##           cube's edges as thicker glass) on pale shelves; walking past, their depths
##           overlap and the colours multiply into each other
## Glass can only darken: where the painting's inner square is lighter than what the
## outer glass lets through (most of this palette), the glass square stays at that light.
## Glass is FILTER (multiply), never alpha: transmitted = behind x transmittance, per
## channel, and multiplication commutes, so no draw order is needed.
@export_enum("paint", "relief", "cubes") var medium: String = "paint":
	set(value):
		var word: String = _medium_word(value)
		if word == medium:
			return
		medium = word
		if _built:
			_rebuild()

const MEDIA: PackedStringArray = ["paint", "relief", "cubes"]
const RELIEF_SLAB_DEPTH := 0.006
const RELIEF_STEP := 0.03
const CUBE_STANDOFF := 0.05
## cubes only: the nest is 85% of the painted square, so the gap between neighbours
## (0.169 m against 0.291 m of depth) clears a ~30 degree cone instead of ~19 degrees,
## and walking past shows a mixture rather than black. vertical_bias scales with it.
const CUBE_SCALE := 0.85
## cubes only: 12 bars along the OUTER cube's edges, inside its shell, in its own face
## colour. A ray through a bar crosses it twice, so an edge reads as thicker glass
## (T0^3 against the band's T0): a frame head-on, two offset outlines in perspective.
const EDGE_BAR := 0.006
const SHELF_THICKNESS := 0.012
## The shelf runs from the light table to this far past the cube's front face.
const SHELF_OVERHANG := 0.02
const SHELF_CLEARANCE := 0.0005
## Shelves belong to the light table: the top IS the table (so a ray through a cube's
## bottom onto the shelf still sees B), the other faces a step darker in sRGB so the
## ledge reads as a line. Order: +x, -x, +y, -y, +z, -z.
const SHELF_SHADES: PackedFloat32Array = [0.86, 0.86, 1.0, 0.80, 0.72, 0.80]
## Glass squares stay this far inside the square they nest in (containment is what
## makes "a ray crosses every outer layer" true; vertical_bias can break it).
const NEST_MARGIN := 0.002

var _paint_material: StandardMaterial3D
var _frame_material: StandardMaterial3D
var _canvas_material: StandardMaterial3D
var _wall_material: StandardMaterial3D
var _wall_size: Vector2

var _built: bool = false
var _ever_ready: bool = false
var _built_nodes: Array[Node] = []
## How many times a medium has been built on this node (the probe reads it: a glass
## record stamped before add_child must build ONCE, not paint-then-glass).
var _build_count: int = 0

func _ready() -> void:
	# The Void stamps config_* metas before add_child, so a glass record builds glass
	# the first time. Read on the FIRST ready only: a later re-entry keeps whatever
	# apply_grid_config or the setter chose since.
	if not _ever_ready:
		_ever_ready = true
		if has_meta("config_medium"):
			medium = _medium_word(get_meta("config_medium"))
	_clear_built()
	_build_medium()


func _medium_word(value: Variant) -> String:
	var w: String = str(value).strip_edges().to_lower()
	if MEDIA.has(w):
		return w
	push_warning("albers_wall_gallery: unknown medium '%s' - using 'paint'" % w)
	return "paint"


func _build_medium() -> void:
	var before: Array[Node] = get_children()
	if medium == "paint":
		# Today's build, byte for byte. Nothing below may change it.
		_ensure_materials()
		_build_wall()
		_build_canvases()
		_build_lighting()
	else:
		_build_glass()
	for c in get_children():
		if not before.has(c):
			_built_nodes.append(c)
	_built = true
	_build_count += 1


func _clear_built() -> void:
	for n in _built_nodes:
		if is_instance_valid(n):
			if n.get_parent() == self:
				remove_child(n)
			n.queue_free()
	_built_nodes.clear()
	for k in ["glass_medium", "glass_clamped", "glass_clamped_squares", "glass_mul_gain",
			"glass_mul_gain_source", "glass_bias_held", "glass_blend_space"]:
		if has_meta(k):
			remove_meta(k)
	_built = false


func _rebuild() -> void:
	_clear_built()
	_build_medium()

func _ensure_materials() -> void:
	_paint_material = StandardMaterial3D.new()
	_paint_material.vertex_color_use_as_albedo = true
	_paint_material.albedo_color = Color.WHITE
	_paint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_paint_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_paint_material.roughness = 0.9
	_paint_material.metallic = 0.0

	_frame_material = _make_solid_material(frame_color, 0.85)
	_canvas_material = _make_solid_material(canvas_color, 0.9)
	_wall_material = _make_solid_material(wall_color, 0.95)

func _build_wall() -> void:
	var width = columns * canvas_size + (columns - 1) * gap + wall_margin * 2.0
	var height = rows * canvas_size + (rows - 1) * gap + wall_margin * 2.0
	_wall_size = Vector2(width, height)

	if show_wall:
		var wall = MeshInstance3D.new()
		wall.name = "AlbersWall"
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(width, height, wall_depth)
		wall.mesh = wall_mesh
		wall.material_override = _wall_material
		wall.position = Vector3(0.0, height * 0.5, 0.0)
		add_child(wall)

	if show_floor:
		var floor = MeshInstance3D.new()
		floor.name = "GalleryFloor"
		var floor_mesh = BoxMesh.new()
		floor_mesh.size = Vector3(width + 2.0, 0.08, 3.0)
		floor.mesh = floor_mesh
		floor.material_override = _make_solid_material(Color(0.94, 0.94, 0.94, 1.0), 0.92)
		floor.position = Vector3(0.0, -0.04, 1.1)
		add_child(floor)

func _build_canvases() -> void:
	var width = _wall_size.x
	var height = _wall_size.y
	var start_x = -width * 0.5 + wall_margin + canvas_size * 0.5
	var start_y = wall_margin + canvas_size * 0.5
	var wall_front = wall_depth * 0.5 if show_wall else 0.0
	var frame_z = wall_front + frame_depth * 0.5 + 0.01
	var canvas_z = wall_front + canvas_depth * 0.5 + 0.015
	var paint_z = wall_front + canvas_depth + 0.02

	var index = 0
	for row in range(rows):
		var y = start_y + (rows - 1 - row) * (canvas_size + gap)
		for col in range(columns):
			if index >= total_canvases:
				return
			var x = start_x + col * (canvas_size + gap)
			var canvas_root = Node3D.new()
			canvas_root.name = "Canvas_%02d" % index
			canvas_root.position = Vector3(x, y, 0.0)
			add_child(canvas_root)

			if show_frames:
				# Create 4-bar picture frame (hollow, not solid)
				var half_size = canvas_size * 0.5
				var bar_length = canvas_size + frame_thickness * 2.0
				
				# Top bar
				var top_bar = MeshInstance3D.new()
				var top_mesh = BoxMesh.new()
				top_mesh.size = Vector3(bar_length, frame_thickness, frame_depth)
				top_bar.mesh = top_mesh
				top_bar.material_override = _frame_material
				top_bar.position = Vector3(0.0, half_size + frame_thickness * 0.5, frame_z)
				canvas_root.add_child(top_bar)
				
				# Bottom bar
				var bottom_bar = MeshInstance3D.new()
				bottom_bar.mesh = top_mesh
				bottom_bar.material_override = _frame_material
				bottom_bar.position = Vector3(0.0, -half_size - frame_thickness * 0.5, frame_z)
				canvas_root.add_child(bottom_bar)
				
				# Left bar
				var left_bar = MeshInstance3D.new()
				var side_mesh = BoxMesh.new()
				side_mesh.size = Vector3(frame_thickness, canvas_size, frame_depth)
				left_bar.mesh = side_mesh
				left_bar.material_override = _frame_material
				left_bar.position = Vector3(-half_size - frame_thickness * 0.5, 0.0, frame_z)
				canvas_root.add_child(left_bar)
				
				# Right bar
				var right_bar = MeshInstance3D.new()
				right_bar.mesh = side_mesh
				right_bar.material_override = _frame_material
				right_bar.position = Vector3(half_size + frame_thickness * 0.5, 0.0, frame_z)
				canvas_root.add_child(right_bar)

			if show_canvas:
				var canvas = MeshInstance3D.new()
				var canvas_mesh = BoxMesh.new()
				canvas_mesh.size = Vector3(canvas_size, canvas_size, canvas_depth)
				canvas.mesh = canvas_mesh
				canvas.material_override = _canvas_material
				canvas.position = Vector3(0.0, 0.0, canvas_z)
				canvas_root.add_child(canvas)

			var palette = _generate_palette(index)
			var painting = MeshInstance3D.new()
			painting.mesh = _make_homage_mesh(canvas_size, palette)
			painting.material_override = _paint_material
			painting.position = Vector3(0.0, 0.0, paint_z)
			canvas_root.add_child(painting)

			index += 1

func _build_lighting() -> void:
	var ambient = DirectionalLight3D.new()
	ambient.name = "AmbientFill"
	ambient.light_energy = ambient_energy
	ambient.rotation_degrees = Vector3(-35.0, 15.0, 0.0)
	add_child(ambient)

	if spot_count <= 0:
		return

	var width = _wall_size.x
	var height = _wall_size.y
	for i in range(spot_count):
		var t = 0.5 if spot_count == 1 else float(i) / float(spot_count - 1)
		var x = lerp(-width * 0.45, width * 0.45, t)
		var spot = SpotLight3D.new()
		spot.name = "Spot_%02d" % i
		spot.light_energy = spot_energy
		spot.light_color = spot_color
		spot.spot_angle = spot_angle
		spot.spot_range = spot_range
		spot.shadow_enabled = true
		spot.position = Vector3(x, height + 0.4, spot_distance)
		var target = Vector3(x, height * 0.45, 0.0)
		spot.look_at_from_position(spot.position, target, Vector3.UP)
		add_child(spot)

func _generate_palette(index: int) -> Array[Color]:
	var rng = RandomNumberGenerator.new()
	rng.seed = palette_seed + index * 31

	var base_hue = fposmod(0.61803398875 * float(index), 1.0)
	var hue_span = rng.randf_range(0.18, 0.36)
	var sat_outer = rng.randf_range(palette_saturation_min, palette_saturation_max)
	var val_outer = rng.randf_range(palette_value_min, palette_value_max)
	var sat_inner = rng.randf_range(max(0.4, palette_saturation_min), palette_saturation_max)
	var val_inner = rng.randf_range(max(0.7, palette_value_min), palette_value_max)

	var palette: Array[Color] = []
	for i in range(squares_per_canvas):
		var t = 0.0 if squares_per_canvas == 1 else float(i) / float(squares_per_canvas - 1)
		var hue = fposmod(base_hue + t * hue_span + rng.randf_range(-0.03, 0.03), 1.0)
		var sat = lerp(sat_outer, sat_inner, t)
		var val = lerp(val_outer, val_inner, t)
		palette.append(Color.from_hsv(hue, sat, val))
	return palette

func _make_homage_mesh(size: float, palette: Array[Color]) -> ArrayMesh:
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	var count = palette.size()
	var max_size = size * (1.0 - border_ratio * 2.0)
	var base_index = 0

	for i in range(count):
		var s = max_size * pow(inset_ratio, i)
		var half_s = s * 0.5
		var t = 0.0 if count <= 1 else float(i) / float(count - 1)
		var y_bias = vertical_bias * size * t
		var color = palette[i]

		vertices.append(Vector3(-half_s, -half_s + y_bias, 0.0))
		vertices.append(Vector3(half_s, -half_s + y_bias, 0.0))
		vertices.append(Vector3(half_s, half_s + y_bias, 0.0))
		vertices.append(Vector3(-half_s, half_s + y_bias, 0.0))

		for _j in range(4):
			normals.append(Vector3(0.0, 0.0, 1.0))
			colors.append(color)
			uvs.append(Vector2.ZERO)

		indices.append(base_index + 0)
		indices.append(base_index + 1)
		indices.append(base_index + 2)
		indices.append(base_index + 0)
		indices.append(base_index + 2)
		indices.append(base_index + 3)

		base_index += 4

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	if vertices.size() > 0:
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func _make_solid_material(color: Color, roughness: float) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.0
	return mat

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
	# A re-entered node rebuilds instead of standing empty: _ready runs again on the
	# next add_child, clears what was queued here and builds the current medium.
	_built = false
	request_ready()


## The grid's hook (token `albers_wall_gallery:180:0.5#medium:cubes`, Void record
## `"config": {"medium": "cubes"}`). Reads `medium` only, and rebuilds ONCE, only when
## the word changes: {}, {"museum_yaw": 0}, {"emissive": false} and a repeat of the same
## dict are no-ops (the Void calls this after add_child, on a node _ready already built
## from the config_medium meta). Before _ready it only stores. An unknown word warns
## and falls back to paint.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("medium"):
		return
	var word: String = _medium_word(config["medium"])
	if word == medium:
		return
	medium = word


# ------------------------------------------------------------------ glass media
#
# Physics: real coloured glass subtracts. transmitted = behind x T, per channel.
# Solve, in linear light, per canvas, from the painting's palette C_0..C_4 over the
# light table B:   A_-1 = B;  T_k = clamp(C_k / A_k-1, 0, 1);  A_k = T_k * A_k-1.
# A channel where the clamp fired is CLAMPED: glass cannot give back light the outer
# glass took away; Albers' opaque paper can. The totals go to metadata.
#
# relief: a ray crosses each slab's front once (CULL_BACK), so face = T_k.
# cubes:  each cube is a closed shell drawn CULL_DISABLED, so a ray crosses it twice,
#         entering and leaving: face = sqrt(T_k), and the two crossings give T_k.
#
# Vertex colours are stored as sRGB BYTES (Godot keeps ARRAY_COLOR as RGBA8) and the
# material decodes them (vertex_color_is_srgb). The solve runs on the bytes the mesh
# actually holds: each layer is solved against the product the quantised outer layers
# really give, so the 8-bit error does not accumulate down the nest. B is likewise the
# light table's stored byte, decoded.

## A merged, single-surface triangle list cut from Godot's own BoxMesh arrays.
class GlassAcc:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var i := PackedInt32Array()

	func add_box(tpl: Dictionary, size: Vector3, center: Vector3, color: Color) -> void:
		var base: int = v.size()
		var tv: PackedVector3Array = tpl["v"]
		var tn: PackedVector3Array = tpl["n"]
		var ti: PackedInt32Array = tpl["i"]
		for k in tv.size():
			v.append(tv[k] * size + center)
			n.append(tn[k])
			c.append(color)
		for k in ti.size():
			i.append(ti[k] + base)

	## The same box with one colour per face, picked by the template normal
	## (+x, -x, +y, -y, +z, -z).
	func add_box_faces(tpl: Dictionary, size: Vector3, center: Vector3, faces: Array) -> void:
		var base: int = v.size()
		var tv: PackedVector3Array = tpl["v"]
		var tn: PackedVector3Array = tpl["n"]
		var ti: PackedInt32Array = tpl["i"]
		for k in tv.size():
			v.append(tv[k] * size + center)
			n.append(tn[k])
			var d: Vector3 = tn[k]
			var ax: int = d.abs().max_axis_index()
			c.append(faces[ax * 2 + (0 if d[ax] > 0.0 else 1)])
		for k in ti.size():
			i.append(ti[k] + base)

	func append(o: GlassAcc) -> void:
		var base: int = v.size()
		v.append_array(o.v)
		n.append_array(o.n)
		c.append_array(o.c)
		for k in o.i.size():
			i.append(o.i[k] + base)

	func to_mesh() -> ArrayMesh:
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_NORMAL] = n
		arrays[Mesh.ARRAY_COLOR] = c
		arrays[Mesh.ARRAY_INDEX] = i
		var m := ArrayMesh.new()
		if v.size() > 0:
			m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return m


## Godot's unit box as {"v","n","i"} (Godot's winding: front faces clockwise). With
## drop_back the two -Z triangles go and the vertex list is compacted: a relief slab is
## its front face and four sides.
static func _box_template(drop_back: bool) -> Dictionary:
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var arr: Array = box.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	if not drop_back:
		return {"v": v, "n": n, "i": idx}
	var remap: Dictionary = {}
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	var oi := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		var tri: Array = [idx[t], idx[t + 1], idx[t + 2]]
		if n[tri[0]].z < -0.5 and n[tri[1]].z < -0.5 and n[tri[2]].z < -0.5:
			continue
		for j in tri:
			if not remap.has(j):
				remap[j] = ov.size()
				ov.append(v[j])
				on.append(n[j])
			oi.append(remap[j])
	return {"v": ov, "n": on, "i": oi}


static func _lin(x: float) -> float:
	return x / 12.92 if x < 0.04045 else pow((x + 0.055) / 1.055, 2.4)


static func _srgb(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * 12.92 if x < 0.0031308 else 1.055 * pow(x, 1.0 / 2.4) - 0.055


## What a stored byte reads back as (float32, as the engine decodes RGBA8).
static func _byte_value(q: int) -> float:
	return Color(q / 255.0, 0.0, 0.0, 1.0).r


static func _bytes_of(c: Color) -> Vector3i:
	return Vector3i(clampi(roundi(c.r * 255.0), 0, 255), clampi(roundi(c.g * 255.0), 0, 255),
		clampi(roundi(c.b * 255.0), 0, 255))


## The colour handed to the mesh for a byte triple. +0.25 lands on the same byte
## whether the encoder truncates or rounds.
static func _encode(q: Vector3i) -> Color:
	return Color((q.x + 0.25) / 255.0, (q.y + 0.25) / 255.0, (q.z + 0.25) / 255.0, 1.0)


static func _decoded(q: Vector3i) -> Color:
	return Color(_byte_value(q.x), _byte_value(q.y), _byte_value(q.z), 1.0)


## The filter solve for one canvas. passes = 1 (relief) or 2 (cubes: face = sqrt(T)).
## Returns {"faces": Array[Vector3i] sRGB bytes, "clamped": channels, "clamped_squares": layers}.
## srgb_space: the framebuffer multiplies sRGB values (Compatibility), so the solve and the
## stored face bytes stay in sRGB; otherwise linear light, faces stored sRGB-encoded.
static func _solve_glass(palette: Array[Color], table: Vector3i, passes: int, srgb_space: bool = false) -> Dictionary:
	var s: bool = srgb_space
	var a: Array[float] = [_to_blend(_byte_value(table.x), s), _to_blend(_byte_value(table.y), s),
		_to_blend(_byte_value(table.z), s)]
	var faces: Array[Vector3i] = []
	var clamped: int = 0
	var clamped_squares: int = 0
	for k in palette.size():
		var col: Color = palette[k]
		var q := Vector3i()
		var hit: bool = false
		for ch in 3:
			var target: float = _to_blend(col[ch], s)
			var t: float = 1.0
			if target > a[ch]:
				clamped += 1
				hit = true
			elif a[ch] > 0.0:
				t = target / a[ch]
			t = clampf(t, 0.0, 1.0)
			var goal: float = a[ch] * t
			var face: float = sqrt(t) if passes == 2 else t
			var q0: int = clampi(roundi(_from_blend(face, s) * 255.0), 0, 255)
			var best: int = q0
			var best_err: float = INF
			for cand in [q0 - 1, q0, q0 + 1]:
				if cand < 0 or cand > 255:
					continue
				var out: float = a[ch] * pow(_to_blend(_byte_value(cand), s), passes)
				var err: float = absf(_from_blend(out, s) - _from_blend(goal, s))
				if err < best_err:
					best_err = err
					best = cand
			q[ch] = best
			a[ch] = a[ch] * pow(_to_blend(_byte_value(best), s), passes)
		if hit:
			clamped_squares += 1
		faces.append(q)
	return {"faces": faces, "clamped": clamped, "clamped_squares": clamped_squares}


## The multiply operand's gain per renderer, MEASURED (SPEC §5 step 5, the fallback the
## spec names). Godot's Mobile renderer keeps its 3D buffer at half luminance, and the
## fragment a BLEND_MODE_MUL material hands the blender is halved with it, so every glass
## layer multiplied by T/2: probe_albers_glass_render.gd measured a linear gain of
## 0.498 / 0.513 / 0.498 for one StandardMaterial3D layer under --rendering-method mobile
## (2026-10-27, RTX 3070), and the centre of a five-layer relief went to 0.028 or black.
## Forward+ measured 1.00. The shader below multiplies its operand back up by this gain.
## The gain is the 3D buffer's LUMINANCE MULTIPLIER, a property of the buffer and not of
## the renderer's name: Mobile stores its 10-bit buffer at 1/2 (headroom), and the same
## renderer with use_hdr_2d renders into a float buffer at 1/1. Measured on every path
## (ada_run/albers_glass_oracle.json, RTX 3070, 2026-10-27):
##   mobile, SubViewport or root window, use_hdr_2d off   2.0
##   mobile, use_hdr_2d on                               1.0  (2.0 doubled each layer: x32 at the centre)
##   forward_plus, either                                 1.0
##   gl_compatibility                                     1.0, and it multiplies sRGB values
##                                                        (OUTPUT_IS_SRGB): solved in sRGB space
## Not measured: the Quest itself (XR swapchain). So the rule is a DEFAULT and the project
## setting below wins when set: a headset-measured value lands as
## `ada/albers_glass/mul_gain.android=<g>` (Godot's feature-tag override) in project.godot,
## with no code change.
const GLASS_GAIN_SETTING := "ada/albers_glass/mul_gain"

## Filter glass as a shader: BLEND_MODE_MUL, unshaded, sRGB vertex colours decoded to
## linear exactly where BaseMaterial3D decodes them (not when the output is already sRGB),
## no depth write (transparent pass), no fog, no shadows. CULL is spliced in.
const GLASS_SHADER := """shader_type spatial;
render_mode unshaded, blend_mul, %s, depth_draw_opaque, shadows_disabled, fog_disabled;
uniform float gain = 1.0;
varying vec3 lin_color;
void vertex() {
	vec3 c = COLOR.rgb;
	if (!OUTPUT_IS_SRGB) {
		c = mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
	}
	lin_color = c;
}
void fragment() {
	ALBEDO = lin_color * gain;
	ALPHA = 1.0;
}
"""

## One compiled Shader per cull mode for every wall and every rebuild; only the
## ShaderMaterial (which carries the gain) is new per build.
static var _glass_shaders: Dictionary = {}


## [gain, where it came from] for the viewport the wall renders into. The project
## setting wins when it is set above 0.
static func _glass_gain_source(vp: Viewport) -> Array:
	var forced: Variant = ProjectSettings.get_setting(GLASS_GAIN_SETTING, 0.0)
	if (forced is float or forced is int) and float(forced) > 0.0:
		return [float(forced), "setting"]
	var method: String = RenderingServer.get_current_rendering_method()
	var hdr: bool = vp != null and vp.use_hdr_2d
	var gain: float = 2.0 if method == "mobile" and not hdr else 1.0
	return [gain, "rule:%s%s" % [method, "+hdr_2d" if hdr else ""]]


func _glass_gain() -> float:
	return float(_glass_gain_source(get_viewport())[0])


## Compatibility blends sRGB-encoded values (OUTPUT_IS_SRGB; the shader then skips its
## decode, as BaseMaterial3D does), so its multiply is solved in sRGB space.
static func _blend_space_srgb() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"


## Into and out of the space the framebuffer multiplies in.
static func _to_blend(x: float, srgb_space: bool) -> float:
	return x if srgb_space else _lin(x)


static func _from_blend(x: float, srgb_space: bool) -> float:
	return clampf(x, 0.0, 1.0) if srgb_space else _srgb(x)


func _make_glass_material(cull: BaseMaterial3D.CullMode) -> ShaderMaterial:
	var key: String = "cull_disabled" if cull == BaseMaterial3D.CULL_DISABLED else "cull_back"
	if not _glass_shaders.has(key):
		var sh := Shader.new()
		sh.code = GLASS_SHADER % key
		_glass_shaders[key] = sh
	var m := ShaderMaterial.new()
	m.shader = _glass_shaders[key]
	m.render_priority = -1
	m.set_shader_parameter("gain", _glass_gain())
	return m


func _make_backing_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.albedo_color = Color.WHITE
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.disable_receive_shadows = true
	# The solve assumes B is the stored byte: fog would tint the table with distance
	# (the Void's depth fog starts at 6 m) while the glass, fog_disabled, would not.
	m.disable_fog = true
	m.metallic = 0.0
	return m


## The 12 edge bars of one cube, inside its shell and not overlapping each other: the
## four along x run the full edge, the eight along y and z stop at the x bars.
static func _add_edge_bars(acc: GlassAcc, tpl: Dictionary, c: Vector3, s: float, color: Color) -> void:
	var e: float = minf(EDGE_BAR, s * 0.25)
	var o: float = (s - e) * 0.5
	var inner: float = s - 2.0 * e
	for a in [-1.0, 1.0]:
		for b in [-1.0, 1.0]:
			acc.add_box(tpl, Vector3(s, e, e), c + Vector3(0.0, a * o, b * o), color)
			acc.add_box(tpl, Vector3(e, inner, e), c + Vector3(a * o, 0.0, b * o), color)
			acc.add_box(tpl, Vector3(e, e, inner), c + Vector3(a * o, b * o, 0.0), color)


## relief / cubes. Same canvas grid, same palettes as paint. What stands:
##   GlassBacking   the light table: wall plate in canvas_color (frames and canvases
##                  dropped), and in cubes one shelf per row, cantilevered from the plate,
##                  its top in the table's own colour and its other faces a step darker
##   GlassHomages   every slab or cube of the wall, one surface; in cubes the outer
##                  cube's 12 edge bars follow all the nests (box c*5+k is still canvas
##                  c's layer k)
##   Canvas_NN      empty markers at the canvas positions (the Void's color_04 probe
##                  counts them), meta palette / layers (solved, sRGB) / clamped
##   lights         as paint, but no spot casts a shadow
func _build_glass() -> void:
	var cubes: bool = medium == "cubes"
	var width = columns * canvas_size + (columns - 1) * gap + wall_margin * 2.0
	var height = rows * canvas_size + (rows - 1) * gap + wall_margin * 2.0
	_wall_size = Vector2(width, height)
	var start_x = -width * 0.5 + wall_margin + canvas_size * 0.5
	var start_y = wall_margin + canvas_size * 0.5
	var wall_front = wall_depth * 0.5 if show_wall else 0.0

	var full: Dictionary = _box_template(false)
	var tpl: Dictionary = full if cubes else _box_template(true)
	var passes: int = 2 if cubes else 1
	var srgb_blend: bool = _blend_space_srgb()

	var table: Vector3i = _bytes_of(canvas_color)
	var backing := GlassAcc.new()
	backing.add_box(full, Vector3(width, height, wall_depth),
		Vector3(0.0, height * 0.5, wall_front - wall_depth * 0.5), _encode(table))

	var scale: float = CUBE_SCALE if cubes else 1.0
	var s0: float = canvas_size * (1.0 - border_ratio * 2.0) * scale
	var cube_z: float = wall_front + CUBE_STANDOFF + s0 * 0.5
	var glass := GlassAcc.new()
	var bars := GlassAcc.new()
	var markers: Array[Node3D] = []
	var row_spans: Array = []
	var total_clamped: int = 0
	var total_squares: int = 0
	var held: int = 0

	var index = 0
	for row in range(rows):
		if index >= total_canvases:
			break
		var y = start_y + (rows - 1 - row) * (canvas_size + gap)
		var span := Vector2(INF, -INF)
		for col in range(columns):
			if index >= total_canvases:
				break
			var x = start_x + col * (canvas_size + gap)
			span = Vector2(minf(span.x, x), maxf(span.y, x))
			var palette = _generate_palette(index)
			var solve: Dictionary = _solve_glass(palette, table, passes, srgb_blend)
			var faces: Array = solve["faces"]
			var count: int = palette.size()
			var layers := PackedColorArray()
			var prev_bias: float = 0.0
			for k in count:
				var s: float = s0 * pow(inset_ratio, k)
				var t: float = 0.0 if count <= 1 else float(k) / float(count - 1)
				var y_bias: float = vertical_bias * canvas_size * scale * t
				if k > 0:
					# Hold square k inside square k-1: a part of it outside would be seen
					# through k but not k-1, and the solve assumes every outer layer.
					var room: float = maxf((s0 * pow(inset_ratio, k - 1) - s) * 0.5 - NEST_MARGIN, 0.0)
					var kept: float = clampf(y_bias, prev_bias - room, prev_bias + room)
					if not is_equal_approx(kept, y_bias):
						held += 1
					y_bias = kept
				prev_bias = y_bias
				var size: Vector3
				var center: Vector3
				if cubes:
					size = Vector3(s, s, s)
					center = Vector3(x, y + y_bias, cube_z)
					if k == 0:
						_add_edge_bars(bars, full, center, s, _encode(faces[0]))
				else:
					size = Vector3(s, s, RELIEF_SLAB_DEPTH)
					center = Vector3(x, y + y_bias,
						wall_front + canvas_depth + 0.02 + k * RELIEF_STEP + RELIEF_SLAB_DEPTH * 0.5)
				glass.add_box(tpl, size, center, _encode(faces[k]))
				layers.append(_decoded(faces[k]))
			var marker := Node3D.new()
			marker.name = "Canvas_%02d" % index
			marker.position = Vector3(x, y, 0.0)
			marker.set_meta("palette", PackedColorArray(palette))
			marker.set_meta("layers", layers)
			marker.set_meta("clamped", int(solve["clamped"]))
			markers.append(marker)
			total_clamped += int(solve["clamped"])
			total_squares += int(solve["clamped_squares"])
			index += 1
		row_spans.append([y, span])

	if held > 0:
		push_warning("albers_wall_gallery: vertical_bias %.3f would push %d glass squares out of the square they nest in - held inside" % [vertical_bias, held])

	if cubes:
		glass.append(bars)
		var shelf_faces: Array = []
		for shade in SHELF_SHADES:
			shelf_faces.append(_encode(Vector3i(roundi(table.x * shade), roundi(table.y * shade),
				roundi(table.z * shade))))
		var z_back: float = wall_front
		var z_front: float = cube_z + s0 * 0.5 + SHELF_OVERHANG
		for rs in row_spans:
			var y: float = rs[0]
			var span: Vector2 = rs[1]
			var shelf_w: float = span.y - span.x + canvas_size
			backing.add_box_faces(full, Vector3(shelf_w, SHELF_THICKNESS, z_front - z_back),
				Vector3((span.x + span.y) * 0.5,
					y - s0 * 0.5 - SHELF_CLEARANCE - SHELF_THICKNESS * 0.5, (z_front + z_back) * 0.5),
				shelf_faces)

	var backing_mi := MeshInstance3D.new()
	backing_mi.name = "GlassBacking"
	backing_mi.mesh = backing.to_mesh()
	backing_mi.material_override = _make_backing_material()
	backing_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(backing_mi)

	var glass_mi := MeshInstance3D.new()
	glass_mi.name = "GlassHomages"
	glass_mi.mesh = glass.to_mesh()
	glass_mi.material_override = _make_glass_material(
		BaseMaterial3D.CULL_DISABLED if cubes else BaseMaterial3D.CULL_BACK)
	glass_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glass_mi)

	for m in markers:
		add_child(m)

	if show_floor:
		var floor = MeshInstance3D.new()
		floor.name = "GalleryFloor"
		var floor_mesh = BoxMesh.new()
		floor_mesh.size = Vector3(width + 2.0, 0.08, 3.0)
		floor.mesh = floor_mesh
		floor.material_override = _make_solid_material(Color(0.94, 0.94, 0.94, 1.0), 0.92)
		floor.position = Vector3(0.0, -0.04, 1.1)
		add_child(floor)

	var before_lights: int = get_child_count()
	_build_lighting()
	for i in range(before_lights, get_child_count()):
		var l := get_child(i) as SpotLight3D
		if l != null:
			l.shadow_enabled = false

	set_meta("glass_medium", medium)
	set_meta("glass_clamped", total_clamped)
	set_meta("glass_clamped_squares", total_squares)
	var gs: Array = _glass_gain_source(get_viewport())
	set_meta("glass_mul_gain", gs[0])
	set_meta("glass_mul_gain_source", gs[1])
	set_meta("glass_blend_space", "srgb" if srgb_blend else "linear")
	set_meta("glass_bias_held", held)
