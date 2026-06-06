extends Node3D
class_name BarnsleyFern

## Barnsley fern — iterated function system rendered as a point cloud on a floor-lying quad.
## Four affine transforms with weighted probabilities produce the classic fern shape.

# @identity
# essence: a floor-lying quad whose texture is painted by the chaos game — a
#   single point is hit 50,000 times by one of four affine maps chosen at
#   random, and where it lands it deposits green. No point knows it is a fern;
#   the fern is the SET the maps agree on. This is the ITERATED FUNCTION SYSTEM
#   made visible: a shape defined not by its outline but by the transforms that
#   leave it invariant.
# desire: to prove that infinite detail can be stored in four little matrices.
#   The fern wants to show that a living-looking form needs no designer of
#   leaves — only a rule, a die, and patience. It is the smallest argument that
#   self-similarity is compression.
# critical_parameter: num_points — the number of chaos-game iterations. Too few
#   and the attractor is a scatter of dust; enough and the fern condenses out of
#   the noise. The seed (_rng.seed = 42) fixes WHICH dust, but the COUNT decides
#   whether the fern exists at all.
# triggers: _ready() builds the floor quad then runs the chaos game into a
#   256x256 image, splatting one of four weighted affine transforms per step
# emerges: low num_points reads NOISE / NOT-YET-FORM; full count reads FERN /
#   ATTRACTOR. Same four transforms, the iteration count IS the difference
#   between dust and frond
# relationships: sibling to other fractals (all define shape by recursion, not
#   by boundary); cousin to noise artifacts (both fill a plane from randomness,
#   but the fern's randomness CONVERGES while noise's stays scattered); peer to
#   l-system growth (both grow a plant from a rule, the fern by probability, the
#   l-system by rewriting)
# truth: an iterated function system is the rule that a fractal is the unique
#   compact set fixed by a finite collection of contraction maps. The fern IS
#   that fixed point — drawn not by deciding where leaves go, but by letting the
#   maps decide, forever, until only the invariant set remains lit.

# --- Configuration ---

@export var quad_size: Vector2 = Vector2(0.6, 0.8)
@export var num_points: int = 50000

const IMAGE_W: int = 256
const IMAGE_H: int = 256
const BG_COLOR: Color = Color(0.04, 0.05, 0.04)
const FERN_COLOR: Color = Color(0.15, 0.75, 0.2)
const FERN_TIP_COLOR: Color = Color(0.4, 0.95, 0.3)

var _mesh_inst: MeshInstance3D
var _material: StandardMaterial3D
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 42
	_build_floor_quad()
	_generate_texture()


func _build_floor_quad() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "FernMesh"
	var quad := QuadMesh.new()
	quad.size = quad_size
	_mesh_inst.mesh = quad
	_mesh_inst.rotation_degrees.x = -90
	_mesh_inst.position.y = 0.005

	_material = StandardMaterial3D.new()
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.roughness = 0.85
	_material.metallic = 0.0
	_mesh_inst.material_override = _material
	add_child(_mesh_inst)


func _generate_texture() -> void:
	# Run the IFS to collect all points
	var points := PackedVector2Array()
	var x := 0.0
	var y := 0.0

	for i in range(num_points):
		var r := _rng.randf()
		var nx: float
		var ny: float

		if r < 0.01:
			# Stem
			nx = 0.0
			ny = 0.16 * y
		elif r < 0.86:
			# Successively smaller copies (main frond)
			nx = 0.85 * x + 0.04 * y
			ny = -0.04 * x + 0.85 * y + 1.6
		elif r < 0.93:
			# Left leaflet
			nx = 0.2 * x - 0.26 * y
			ny = 0.23 * x + 0.22 * y + 1.6
		else:
			# Right leaflet
			nx = -0.15 * x + 0.28 * y
			ny = 0.26 * x + 0.24 * y + 0.44

		x = nx
		y = ny
		points.append(Vector2(x, y))

	# Find bounding box
	var min_x := 1e10
	var max_x := -1e10
	var min_y := 1e10
	var max_y := -1e10
	for pt in points:
		min_x = minf(min_x, pt.x)
		max_x = maxf(max_x, pt.x)
		min_y = minf(min_y, pt.y)
		max_y = maxf(max_y, pt.y)

	var range_x := max_x - min_x
	var range_y := max_y - min_y
	if range_x < 0.001 or range_y < 0.001:
		return

	# Create image and plot points
	var image := Image.create(IMAGE_W, IMAGE_H, false, Image.FORMAT_RGBA8)
	image.fill(BG_COLOR)

	# Accumulation buffer for density-based coloring
	var density := PackedInt32Array()
	density.resize(IMAGE_W * IMAGE_H)
	density.fill(0)

	var margin := 4
	var draw_w := IMAGE_W - margin * 2
	var draw_h := IMAGE_H - margin * 2

	# Scale to fit, preserving aspect ratio
	var scale_x := float(draw_w) / range_x
	var scale_y := float(draw_h) / range_y
	var s := minf(scale_x, scale_y)

	var offset_x := margin + int((draw_w - range_x * s) * 0.5)
	var offset_y := margin + int((draw_h - range_y * s) * 0.5)

	for pt in points:
		var px := int((pt.x - min_x) * s) + offset_x
		# Flip Y so fern grows upward in texture
		var py := (IMAGE_H - 1) - (int((pt.y - min_y) * s) + offset_y)
		if px >= 0 and px < IMAGE_W and py >= 0 and py < IMAGE_H:
			var idx := py * IMAGE_W + px
			density[idx] += 1

	# Render density to image — brighter where more points overlap
	var max_density := 1
	for d in density:
		if d > max_density:
			max_density = d

	for py in range(IMAGE_H):
		for px in range(IMAGE_W):
			var d := density[py * IMAGE_W + px]
			if d > 0:
				var t := clampf(float(d) / float(max_density), 0.0, 1.0)
				# Sqrt for gamma — makes dim areas more visible
				t = sqrt(t)
				var color := FERN_COLOR.lerp(FERN_TIP_COLOR, t)
				image.set_pixel(px, py, color)

	var texture := ImageTexture.create_from_image(image)
	_material.albedo_texture = texture


## Grid system integration — accept configuration from map data
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("num_points"):
		num_points = int(config_data["num_points"])
	if config_data.has("seed"):
		_rng.seed = int(config_data["seed"])
		_generate_texture()
