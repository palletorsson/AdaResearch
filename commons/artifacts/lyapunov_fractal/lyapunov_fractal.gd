extends Node3D
class_name LyapunovFractal

## Lyapunov fractal — floor display showing the Lyapunov exponent landscape of
## alternating logistic maps. For each pixel (a,b) in [2,4]x[2,4], iterate
## x = r*x*(1-x) alternating r between a and b in pattern "AABB". Compute
## λ = (1/N)Σ log|r*(1-2x)|. Stable (λ<0) = blue, chaotic (λ>0) = yellow/red,
## boundary (λ≈0) = black. The result resembles alien calligraphy.

# @identity
# essence: λ(a,b) = (1/N)Σ log|r(1-2x)|, alternating r between a and b in AABB pattern. Stable regions blue (λ<0), chaotic regions yellow/red (λ>0), boundary black.
# desire: to lay alien calligraphy on the floor — the Lyapunov landscape is a map of two parameters against each other, where the boundary between order and chaos draws itself
# critical_parameter: PATTERN array — changing "AABB" to "AB" or "AAAB" morphs the fractal into different alien script, same math, different handwriting
# triggers: _ready → _generate_texture → per-pixel (a,b) iterate WARMUP+COMPUTE logistic maps → sum log|r(1-2x)| → color blue/black/red by sign
# emerges: the thin black curves of λ≈0 — the exact edge where each parameter combination teeters between repeating and diverging, drawn without any explicit curve equation
# needs: VR parameter walk [missing], PATTERN selector [missing], floor scale control [missing]
# relationships: sibling to cantor_set (both explore what zero looks like); twin to fractal_clouds (both render a scalar field as visual texture); foundation for strange_attractors
# truth: The Lyapunov fractal does not show space — it shows the stability of time. Every pixel is a different universe asking: does this rule converge, or does it spiral into chaos?

# --- Configuration ---

@export var quad_size: Vector2 = Vector2(0.8, 0.8)
@export var seed_value: int = 42

const IMAGE_SIZE: int = 128
const WARMUP_ITERS: int = 50
const COMPUTE_ITERS: int = 200
const PATTERN: Array[int] = [0, 0, 1, 1]  # "AABB" — 0=a, 1=b

# Parameter space bounds
const A_MIN: float = 2.0
const A_MAX: float = 4.0
const B_MIN: float = 2.0
const B_MAX: float = 4.0

var _mesh_inst: MeshInstance3D
var _material: StandardMaterial3D


func _ready() -> void:
	_build_floor_quad()
	_generate_texture()


func _build_floor_quad() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "LyapunovMesh"
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
	var image := Image.create(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBA8)

	# Precompute Lyapunov exponents into a buffer so we can normalize
	var exponents := PackedFloat32Array()
	exponents.resize(IMAGE_SIZE * IMAGE_SIZE)

	var pattern_len := PATTERN.size()
	var total_iters := WARMUP_ITERS + COMPUTE_ITERS

	var min_exp := 1e10
	var max_exp := -1e10

	for py in range(IMAGE_SIZE):
		# Map py to b value (top = B_MAX, bottom = B_MIN for natural orientation)
		var b := lerpf(B_MAX, B_MIN, float(py) / float(IMAGE_SIZE - 1))

		for px in range(IMAGE_SIZE):
			# Map px to a value
			var a := lerpf(A_MIN, A_MAX, float(px) / float(IMAGE_SIZE - 1))

			var r_values: Array[float] = [a, b]
			var x := 0.5  # Initial condition
			var lyap_sum := 0.0

			for i in range(total_iters):
				var r := r_values[PATTERN[i % pattern_len]]
				x = r * x * (1.0 - x)

				# Clamp to avoid degenerate orbits
				x = clampf(x, 1e-10, 1.0 - 1e-10)

				if i >= WARMUP_ITERS:
					var deriv := absf(r * (1.0 - 2.0 * x))
					if deriv > 1e-15:
						lyap_sum += log(deriv)

			var lyap := lyap_sum / float(COMPUTE_ITERS)

			var idx := py * IMAGE_SIZE + px
			exponents[idx] = lyap

			if lyap < min_exp:
				min_exp = lyap
			if lyap > max_exp:
				max_exp = lyap

	# Color the image based on Lyapunov exponent values
	for py in range(IMAGE_SIZE):
		for px in range(IMAGE_SIZE):
			var idx := py * IMAGE_SIZE + px
			var lyap := exponents[idx]
			var color: Color

			if lyap < -0.001:
				# Stable region — blue shades
				# Normalize within negative range: deeper negative = darker blue
				var t := clampf(lyap / min_exp, 0.0, 1.0)
				# t=0 near zero (light blue), t=1 at most negative (deep blue)
				color = Color(
					0.02 + 0.12 * (1.0 - t),
					0.05 + 0.20 * (1.0 - t),
					0.25 + 0.60 * t
				)
			elif lyap > 0.001:
				# Chaotic region — yellow to red
				# Normalize within positive range
				var t := clampf(lyap / max_exp, 0.0, 1.0) if max_exp > 0.001 else 0.0
				# t=0 near zero (yellow), t=1 at most positive (deep red)
				color = Color(
					0.85 + 0.15 * t,
					0.75 * (1.0 - t * 0.8),
					0.05
				)
			else:
				# Boundary — black
				color = Color(0.02, 0.02, 0.02)

			image.set_pixel(px, py, color)

	var texture := ImageTexture.create_from_image(image)
	_material.albedo_texture = texture


## Grid system integration — accept configuration from map data
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("warmup_iters"):
		pass  # Could be extended
	if config_data.has("pattern"):
		pass  # Could accept "AB", "AABB", etc.
