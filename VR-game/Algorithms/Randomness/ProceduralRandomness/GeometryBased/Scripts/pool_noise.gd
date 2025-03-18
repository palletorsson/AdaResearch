extends MeshInstance3D

@export var width: int = 50
@export var depth: int = 50
@export var height_scale: float = 0.1
@export var cell_size: float = 0.1
@export var num_cells: int = 50

@export var num_pools: int = 10
@export var min_pool_radius: float = 1.0
@export var max_pool_radius: float = 5.0
@export var wall_height: float = 0.01

@export var growth_speed: float = 0.1
@export var min_inner_circle_radius: float = 0.5
@export var max_inner_circle_radius: float = 2.0
@export var num_inner_circles: int = 8  # Number of circles per pool

var pools = []  # Stores pool data
var noise = FastNoiseLite.new()
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	create_noise()
	generate_pools()
	generate_grid()
	TimerHelper.create_timer(self, 0.5, Callable(self, "_grow_pools"), false)

func create_noise():
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise.cellular_jitter = 10.0
	noise.frequency = 1.0 / cell_size

func generate_pools():
	pools.clear()
	for i in range(num_pools):
		var pool_center = Vector2(rng.randi_range(5, num_cells - 5), rng.randi_range(5, num_cells - 5))
		var pool_radius = rng.randf_range(min_pool_radius, min_pool_radius + 1.0)
		var inner_circles = generate_circle_packing(pool_center, pool_radius)
		pools.append({ "center": pool_center, "radius": pool_radius, "inner_circles": inner_circles })

func generate_circle_packing(pool_center: Vector2, pool_radius: float) -> Array:
	var circles = []
	var attempts = 0
	while circles.size() < num_inner_circles and attempts < 100:
		var new_circle = {
			"center": Vector2(
				pool_center.x + rng.randf_range(-pool_radius * 0.7, pool_radius * 0.7),
				pool_center.y + rng.randf_range(-pool_radius * 0.7, pool_radius * 0.7)
			),
			"radius": rng.randf_range(min_inner_circle_radius, max_inner_circle_radius)
		}

		# Ensure circles don't overlap too much
		var overlaps = false
		for existing in circles:
			if new_circle["center"].distance_to(existing["center"]) < (new_circle["radius"] + existing["radius"]) * 0.8:
				overlaps = true
				break

		if not overlaps:
			circles.append(new_circle)

		attempts += 1

	return circles

func _grow_pools():
	for pool in pools:
		pool["radius"] = min(pool["radius"] + growth_speed, max_pool_radius)
		for circle in pool["inner_circles"]:
			circle["radius"] = min(circle["radius"] + growth_speed * 0.5, max_inner_circle_radius)

	generate_grid()

func mask_pool_area(x: int, y: int) -> float:
	var min_factor = 1.0
	for pool in pools:
		var pool_center = pool["center"]
		var pool_radius = pool["radius"]
		var distance = Vector2(x, y).distance_to(pool_center)

		if distance < pool_radius:
			min_factor = min(min_factor, 0.2)
		elif distance < pool_radius + 2:
			min_factor = min(min_factor, wall_height)

		# Apply inner circle influence
		for circle in pool["inner_circles"]:
			var circle_distance = Vector2(x, y).distance_to(circle["center"])
			if circle_distance < circle["radius"]:
				min_factor = min(min_factor, 0.3)  # Inner circle influence

	return min_factor

func generate_grid():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = []
	for x in range(num_cells + 1):
		vertices.append([])
		for y in range(num_cells + 1):
			var pos = Vector3(x * cell_size, 0, y * cell_size)

			var noise_factor = mask_pool_area(x, y)
			pos.y = noise.get_noise_2d(pos.x, pos.z) * height_scale * noise_factor

			vertices[x].append(pos)

	for x in range(num_cells):
		for y in range(num_cells):
			var v0 = vertices[x][y]
			var v1 = vertices[x + 1][y]
			var v2 = vertices[x + 1][y + 1]
			var v3 = vertices[x][y + 1]

			st.add_vertex(v0)
			st.add_vertex(v1)
			st.add_vertex(v2)
			st.add_vertex(v0)
			st.add_vertex(v2)
			st.add_vertex(v3)

	st.generate_normals()
	mesh = st.commit()
