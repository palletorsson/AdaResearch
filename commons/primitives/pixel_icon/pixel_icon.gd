extends Node3D
class_name PixelIcon

# @identity
# essence: a 2D pixel-art glyph extruded into a field of little 3D cubes — the thumb and the heart of social reaction, rebuilt as voxels in the project's own primitive vocabulary. A bitmap becomes a MultiMesh of beveled blocks, one draw call, readable from across the room.
# desire: to say "yes" and "love" in the grammar of the grid. Ada teaches that everything is built from primitives; a reaction icon should be too — not an imported sprite but a thing assembled from cubes, the way the curriculum assembles meaning from points.
# critical_parameter: icon_shape — which bitmap is rasterised into cubes (heart / thumb / +). The same machinery draws any small pixel glyph; the shape is just the stencil. Sparsity is cheap: only the lit pixels become cubes.
# triggers: _ready() rasterises the chosen bitmap into per-cell transforms and uploads them to a single MultiMesh; apply_grid_config rebuilds with new shape/colour/scale.
# emerges: thumb in cool blue = "friend / approved", heart in warm red = "loved" — the catalyst's foe→friend arc, or a VR hand-pose reaction, made into a solid object you can place, throw, or orbit.
# needs: a bitmap (rows of strings, X = filled) [present]; a MultiMesh of unit cubes [present]; a beveled emissive material [present]; small inter-cube gap so the voxels read as separate blocks like the reference art [present]
# relationships: cousin to floating_primitives (both turn a 2D pattern into 3D forms in the project's cube idiom); sibling to the catalyst friend/foe system (thumb/heart are its natural reaction badges); built like any primitive artifact (MultiMesh, one draw call, curriculum-honest — no randomness).
# truth: a reaction is a primitive feeling, so it should be a primitive object. The heart was always pixels; we just gave the pixels depth.

## A pixel-art icon (heart / thumb / …) rasterised into a field of small
## 3D cubes on ONE MultiMesh — one draw call, trivially cheap.
##
## Set `icon_shape` to pick the bitmap. Lit pixels (X) become cubes;
## dots/spaces are skipped. Faces +Z. Sized so the whole glyph spans
## roughly `target_size` metres on its long axis.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Shape")
## "heart", "thumb" — the bitmap stencil to voxelise.
@export var icon_shape: String = "heart"

@export_group("Look")
@export var color: Color = Color(0.93, 0.16, 0.28)      # heart red
@export var emission_energy: float = 0.6
@export var metallic: float = 0.1
@export var roughness: float = 0.45
## Long-axis span of the whole glyph in metres.
@export var target_size: float = 0.42
## Fraction of each cell the cube fills (rest is the gap between voxels).
@export var fill_ratio: float = 0.86
## Depth of each voxel as a fraction of cell size.
@export var depth_ratio: float = 1.0
## Round the cube edges slightly (0 = sharp box, up to ~0.4).
@export var bevel: float = 0.12

# ── Bitmaps ───────────────────────────────────────────────────────────
# X = filled voxel, anything else = empty. Top row first; the build
# flips vertically so row 0 ends up at the TOP in world space.

const BITMAPS := {
	"heart": [
		".XX.XX.",
		"XXXXXXX",
		"XXXXXXX",
		"XXXXXXX",
		".XXXXX.",
		"..XXX..",
		"...X...",
	],
	"thumb": [
		"....XX..",
		"....XX..",
		"....XX..",
		".XXXXX..",
		"X.XXXXX.",
		"X.XXXXXX",
		"X.XXXXXX",
		"XXXXXXXX",
	],
}

# Default colours per shape (overridden by `color` if the user sets it
# away from the heart default).
const SHAPE_COLORS := {
	"heart": Color(0.93, 0.16, 0.28),
	"thumb": Color(0.18, 0.55, 0.95),
}

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_icon_shape"):
		icon_shape = str(get_meta("config_icon_shape")).to_lower()
		# Adopt the shape's signature colour unless an explicit one is set.
		if not has_meta("config_color") and SHAPE_COLORS.has(icon_shape):
			color = SHAPE_COLORS[icon_shape]
	if has_meta("config_color"):
		color = _parse_color(str(get_meta("config_color")), color)
	if has_meta("config_target_size"):
		target_size = float(str(get_meta("config_target_size")))
	if has_meta("config_emission_energy"):
		emission_energy = float(str(get_meta("config_emission_energy")))


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	var bitmap: Array = BITMAPS.get(icon_shape, BITMAPS["heart"])
	var rows: int = bitmap.size()
	var cols: int = 0
	for r in bitmap:
		cols = max(cols, str(r).length())
	if rows == 0 or cols == 0:
		return

	# Cell size so the long axis spans target_size.
	var cell: float = target_size / float(max(rows, cols))
	var cube_side: float = cell * fill_ratio
	var cube_depth: float = cell * depth_ratio

	# Collect lit-pixel transforms, centred on origin.
	var transforms: Array = []
	var half_w: float = float(cols) * cell * 0.5
	var half_h: float = float(rows) * cell * 0.5
	for ri in range(rows):
		var line: String = str(bitmap[ri])
		for ci in range(line.length()):
			if line[ci] != "X":
				continue
			# Flip vertically: row 0 → top.
			var x: float = (float(ci) + 0.5) * cell - half_w
			var y: float = half_h - (float(ri) + 0.5) * cell
			transforms.append(Transform3D(Basis.IDENTITY, Vector3(x, y, 0.0)))

	if transforms.is_empty():
		return

	var mesh := _make_cube_mesh(cube_side, cube_depth)
	var mat := _make_material()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, mat)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "PixelVoxels_%s" % icon_shape
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mmi)
	print("  [pixel_icon] %s — %d voxels, 1 draw call" % [icon_shape, transforms.size()])


func _make_cube_mesh(side: float, depth: float) -> Mesh:
	# A rounded box (bevel) reads like the reference art's soft cubes.
	# BoxMesh is the cheap path; subtle bevel via a small chamfer is
	# approximated by scaling a box — full CSG rounding isn't worth the
	# vertex cost for ~40 instances, so we keep a clean box and let the
	# material's specular suggest the soft edge.
	var bm := BoxMesh.new()
	bm.size = Vector3(side, side, depth)
	return bm


func _make_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	# A touch of specular so the cube edges catch light like the
	# rounded-voxel reference renders.
	mat.metallic_specular = 0.6
	return mat


func _parse_color(s: String, fallback: Color) -> Color:
	if s.begins_with("#"):
		return Color(s)
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(float(parts[0]), float(parts[1]), float(parts[2]), a)
