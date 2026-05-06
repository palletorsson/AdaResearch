# SphericalHarmonicsSpace.gd - Spherical harmonics projected as walkable terrain
# The same mathematics that describes electron orbitals, gravitational
# fields, and audio spatialization — projected flat. Walk across
# the lobes of Y_l^m and feel quantum mechanics under your feet.
#
# "The shape of probability. The terrain of the possible."

extends TopologySpace
class_name SphericalHarmonicsSpace

@export var degree_l: int = 3              # Degree (0-6 practical)
@export var order_m: int = 2               # Order (-l to l)
@export var combination_mode: CombineMode = CombineMode.SINGLE

enum CombineMode {
	SINGLE,            # Just one Y_l^m
	SUM_ALL_ORDERS,    # Sum all m for given l
	SUPERPOSITION,     # Weighted mix of multiple (l,m)
	ORBITAL_HYBRID,    # sp3, sp2, sp hybrid-like combinations
}

# Superposition weights (used in SUPERPOSITION mode)
@export var components: Array[Vector3] = []  # Each Vector3 = (l, m, weight)

func _ready():
	if components.is_empty():
		components = [
			Vector3(2, 0, 1.0),
			Vector3(3, 2, 0.7),
			Vector3(4, -3, 0.5),
		]
	super._ready()

func generate_space():
	var heights: Array = []
	var gs = resolution + 1

	for z in range(gs):
		for x in range(gs):
			# Map to spherical-ish coordinates
			var theta = (z / float(resolution)) * PI       # 0 to PI (polar)
			var phi = (x / float(resolution)) * TAU         # 0 to 2PI (azimuthal)

			var h = _compute_sh(theta, phi)
			heights.append(h * height_scale)

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _compute_sh(theta: float, phi: float) -> float:
	match combination_mode:
		CombineMode.SINGLE:
			return _spherical_harmonic(degree_l, order_m, theta, phi)
		CombineMode.SUM_ALL_ORDERS:
			var sum = 0.0
			for m in range(-degree_l, degree_l + 1):
				sum += abs(_spherical_harmonic(degree_l, m, theta, phi))
			return sum
		CombineMode.SUPERPOSITION:
			var sum = 0.0
			for comp in components:
				var l = int(comp.x)
				var m = int(comp.y)
				var w = comp.z
				sum += _spherical_harmonic(l, m, theta, phi) * w
			return sum
		CombineMode.ORBITAL_HYBRID:
			return _orbital_hybrid(theta, phi)
	return 0.0

func _spherical_harmonic(l: int, m: int, theta: float, phi: float) -> float:
	"""Real spherical harmonic Y_l^m(theta, phi)"""
	var plm = _associated_legendre(l, abs(m), cos(theta))

	# Normalization factor
	var norm = sqrt((2.0 * l + 1.0) / (4.0 * PI) * _factorial(l - abs(m)) / _factorial(l + abs(m)))

	if m > 0:
		return norm * plm * cos(m * phi) * sqrt(2.0)
	elif m < 0:
		return norm * plm * sin(abs(m) * phi) * sqrt(2.0)
	else:
		return norm * plm

func _associated_legendre(l: int, m: int, x: float) -> float:
	"""Associated Legendre polynomial P_l^m(x) using recurrence"""
	if m > l:
		return 0.0

	# P_m^m
	var pmm = 1.0
	if m > 0:
		var somx2 = sqrt((1.0 - x) * (1.0 + x))
		var fact = 1.0
		for _i in range(m):
			pmm *= -fact * somx2
			fact += 2.0

	if l == m:
		return pmm

	# P_(m+1)^m
	var pmm1 = x * (2.0 * m + 1.0) * pmm
	if l == m + 1:
		return pmm1

	# Recurrence
	var pll = 0.0
	for ll in range(m + 2, l + 1):
		pll = (x * (2.0 * ll - 1.0) * pmm1 - (ll + m - 1.0) * pmm) / (ll - m)
		pmm = pmm1
		pmm1 = pll

	return pll

func _factorial(n: int) -> float:
	var result = 1.0
	for i in range(2, n + 1):
		result *= i
	return result

func _orbital_hybrid(theta: float, phi: float) -> float:
	"""sp3-like hybrid: combination of s and p orbitals"""
	var s = _spherical_harmonic(0, 0, theta, phi)
	var px = _spherical_harmonic(1, 1, theta, phi)
	var py = _spherical_harmonic(1, -1, theta, phi)
	var pz = _spherical_harmonic(1, 0, theta, phi)
	# One of the four sp3 hybrid lobes
	return (s + px + py + pz) * 0.5

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.35, 0.6)  # Quantum purple
	material.roughness = 0.4
	material.metallic = 0.5
	material.emission_enabled = true
	material.emission = Color(0.3, 0.2, 0.5) * 0.3
	mesh_instance.material_override = material

# Public API
func set_harmonic(l: int, m: int):
	degree_l = clampi(l, 0, 8)
	order_m = clampi(m, -degree_l, degree_l)
	generate_space()

func set_mode(mode: CombineMode):
	combination_mode = mode
	generate_space()
