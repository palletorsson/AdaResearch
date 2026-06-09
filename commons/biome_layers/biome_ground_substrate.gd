# biome_ground_substrate.gd — the walkable bump-map ground for biome maps
#
# Extends the walkgrids TopologySpace (its create_mesh_from_heights +
# create_collision_from_mesh give a deformed, WALKABLE mesh for free). A per-cell
# height field (the "ground" paint layer — plane / random / curve / noise / brush)
# is bilinear-sampled into the mesh; the trimesh collider follows, so the bumps
# are walkable. Flat field (the default) = a level ground at the floor.
# See doc/PAINT_LAYERS.md and doc/VR_EDITING_SYSTEM.md.

extends "res://commons/context/walkgrids/TopologySpace.gd"

const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")
const BiomeElementsLib = preload("res://commons/biome_layers/biome_elements.gd")
const PAINT_RES := 96            # resolution of the colour/bleed paint texture

var _field: PackedFloat32Array = PackedFloat32Array()  # per-cell [0..1] (the bump map)
var _fw: int = 1
var _fd: int = 1
var _max_h: float = 1.2          # metres at field value 1.0
var _paint_layers: Array = []    # for the colour overlay: shader paint + plant bleed
var _rng_seed: int = 0
var _stage_order: int = 999      # curriculum gate: bleed only elements unlocked by this stage (999 = ungated)
# Base elevation of the field-zero plane, relative to the grid center.y. The default
# −1.0 keeps the historic BACKDROP behaviour (a flat scenery ground a metre below the
# grid floor — see PAINT_LAYERS.md decision B). A PAINTED ground field lifts this to
# the floor surface (set_base_offset) so its hills rise VISIBLY above the grid floor
# instead of staying buried under the opaque floor cubes. Set BEFORE configure().
var _base_offset: float = -1.0
var _center: Vector3 = Vector3.ZERO   # cached so set_base_offset can re-place after configure()


## Set the field-zero base elevation (relative to center.y). Usually called BEFORE
## configure(); if called AFTER (e.g. a live preview lifting an already-placed substrate
## from backdrop to floor) it re-positions the node in place. −1.0 = the historic backdrop
## (flat scenery below the floor); a small positive value (≈ floor top) makes a painted
## height-map's hills rise visibly above the grid floor.
func set_base_offset(base_offset: float) -> void:
	_base_offset = base_offset
	if is_inside_tree():
		position = Vector3(_center.x, _center.y + _base_offset, _center.z)


## Size + place the ground to cover the grid (call BEFORE add_child).
func configure(grid_w: int, grid_d: int, cube: float, center: Vector3) -> void:
	space_size = Vector2(float(grid_w) * cube, float(grid_d) * cube)
	# Smooth-ish bumps: a couple of mesh quads per grid cell, capped for perf.
	resolution = clampi(maxi(grid_w, grid_d) * 2, 16, 80)
	height_scale = 1.0
	_center = center
	# Base = grid center plus the configured offset. Flat/backdrop default keeps the
	# ground a metre below the floor; a painted field lifts it to the floor surface so
	# the terrain reads as visible undulating hills (set via set_base_offset).
	position = Vector3(center.x, center.y + _base_offset, center.z)


## Set the height field (the bump map). `field` is row-major fw*fd, values 0..1.
func set_field(field: PackedFloat32Array, fw: int, fd: int, max_h: float) -> void:
	_field = field
	_fw = maxi(1, fw)
	_fd = maxi(1, fd)
	_max_h = max_h


## The full paint-layer list — used for the ground's COLOUR overlay: "shader"
## layers paint their colour; plant layers (tree/flower/…) bleed their kingdom
## colour into the texture. Call before add_child (or before a rebuild).
func set_paint_layers(layers: Array, rng_seed: int, stage_order: int = 999) -> void:
	_paint_layers = layers
	_rng_seed = rng_seed
	_stage_order = stage_order


## TopologySpace._ready() calls this after building static_body/mesh_instance.
func generate_space() -> void:
	var mesh: ArrayMesh = create_mesh_from_heights(_build_heights())
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_apply_ground_material()


## Height-banded earth + a painted/bled colour overlay (shader paint + plant
## bleed). Falls back to a plain material if the shader is missing.
func _apply_ground_material() -> void:
	var shader = load("res://commons/biome_layers/biome_ground.gdshader")
	if shader == null:
		apply_standard_material(Color(0.30, 0.28, 0.24), 0.9, 0.0)
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("color_low", Vector3(0.26, 0.22, 0.17))
	mat.set_shader_parameter("color_mid", Vector3(0.34, 0.40, 0.26))
	mat.set_shader_parameter("color_high", Vector3(0.62, 0.66, 0.52))
	mat.set_shader_parameter("height_min", 0.0)
	mat.set_shader_parameter("height_max", maxf(0.4, _max_h))
	mat.set_shader_parameter("paint_tex", _compose_paint_texture())
	mesh_instance.material_override = mat


## Compose the RGBA paint texture by sampling each layer's field PER PIXEL
## (bilinear) — a smooth, organic overlay that follows the noise/curve/brush
## exactly. "shader" layers paint a chosen colour (strong); plant layers seep
## their kingdom colour (the bleed, softer).
func _compose_paint_texture() -> ImageTexture:
	var img := Image.create(PAINT_RES, PAINT_RES, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Build each contributing layer's field + colour once.
	var contribs: Array = []   # [{field, color, strength}]
	var idx := 0
	for layer in _paint_layers:
		if not (layer is Dictionary):
			continue
		var el := str(layer.get("element", ""))
		# Curriculum honesty: don't bleed a kingdom's colour before its unlock stage
		# (matches the spawn gate — trees only render from seq 11, etc.). The spawn
		# layers were already order-gated; this closes the soil-tint leak.
		if BiomeElementsLib.unlock_order(el) > _stage_order:
			continue
		var tint := _bleed_colour(el, layer)
		if tint.a <= 0.0:
			continue
		contribs.append({
			"field": DistributionField.build_field(layer, _fw, _fd, _rng_seed + idx * 17),
			"color": tint,
			"strength": 0.92 if el == "shader" else 0.55,
		})
		idx += 1
	if contribs.is_empty():
		return ImageTexture.create_from_image(img)
	for py in PAINT_RES:
		var v := (float(py) + 0.5) / float(PAINT_RES)
		for px in PAINT_RES:
			var u := (float(px) + 0.5) / float(PAINT_RES)
			var r := 0.0; var g := 0.0; var b := 0.0; var a := 0.0
			for c in contribs:
				var fv := _sample_array(c.field, u, v)
				if fv <= 0.02:
					continue
				var la := clampf(fv * float(c.strength), 0.0, 0.92)
				var col: Color = c.color
				r = lerpf(r, col.r, la); g = lerpf(g, col.g, la); b = lerpf(b, col.b, la)
				a = maxf(a, la)
			if a > 0.001:
				img.set_pixel(px, py, Color(r, g, b, a))
	return ImageTexture.create_from_image(img)


## Bilinear sample a per-cell field at normalized (u, v).
func _sample_array(field: PackedFloat32Array, u: float, v: float) -> float:
	if field.is_empty():
		return 0.0
	var fx := clampf(u * float(_fw) - 0.5, 0.0, float(_fw - 1))
	var fz := clampf(v * float(_fd) - 0.5, 0.0, float(_fd - 1))
	var x0 := int(floor(fx)); var z0 := int(floor(fz))
	var x1 := mini(x0 + 1, _fw - 1); var z1 := mini(z0 + 1, _fd - 1)
	var tx := fx - float(x0); var tz := fz - float(z0)
	var aa := field[z0 * _fw + x0]; var bb := field[z0 * _fw + x1]
	var cc := field[z1 * _fw + x0]; var dd := field[z1 * _fw + x1]
	return lerpf(lerpf(aa, bb, tx), lerpf(cc, dd, tx), tz)


func _bleed_colour(el: String, layer: Dictionary) -> Color:
	# shader paints its OWN chosen colour into the soil (the layer's "color");
	# every other element uses its kingdom bleed from the element registry.
	if el == "shader":
		var c = layer.get("color", null)
		if c is Array and (c as Array).size() >= 3:
			return Color(float(c[0]), float(c[1]), float(c[2]), 1.0)
	return BiomeElementsLib.bleed_color(el)


## LIVE preview while brushing — rebuild the MESH only (skip the trimesh
## collider, which is the expensive part). The collider catches up on the full
## rebuild at stroke-end. Lets you see the terrain rise under the brush.
func apply_height_preview(field: PackedFloat32Array, fw: int, fd: int, max_h: float) -> void:
	set_field(field, fw, fd, max_h)
	if mesh_instance:
		mesh_instance.mesh = create_mesh_from_heights(_build_heights())


func _build_heights() -> Array:
	var heights: Array = []
	heights.resize((resolution + 1) * (resolution + 1))
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			heights[z * (resolution + 1) + x] = _sample(float(x) / float(resolution), float(z) / float(resolution)) * _max_h
	return heights


## Rebuild from a new field (live brush updates).
func rebuild(field: PackedFloat32Array, fw: int, fd: int, max_h: float) -> void:
	set_field(field, fw, fd, max_h)
	if mesh_instance:   # only after _ready has built the nodes
		generate_space()


## Bilinear sample the per-cell field at normalized (u, v) over the grid.
func _sample(u: float, v: float) -> float:
	if _field.is_empty():
		return 0.0
	var fx: float = clampf(u * float(_fw) - 0.5, 0.0, float(_fw - 1))
	var fz: float = clampf(v * float(_fd) - 0.5, 0.0, float(_fd - 1))
	var x0: int = int(floor(fx))
	var z0: int = int(floor(fz))
	var x1: int = mini(x0 + 1, _fw - 1)
	var z1: int = mini(z0 + 1, _fd - 1)
	var tx: float = fx - float(x0)
	var tz: float = fz - float(z0)
	var a: float = _field[z0 * _fw + x0]
	var b: float = _field[z0 * _fw + x1]
	var c: float = _field[z1 * _fw + x0]
	var d: float = _field[z1 * _fw + x1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)
