extends PaperAlgorithm
class_name PaperKMeans

## K-means clustering — watch points drift toward centroids.

var _w: int
var _h: int
var _points: Array[Vector2] = []
var _centroids: Array[Vector2] = []
var _centroid_colors: Array[Color] = []
var _assignments: Array[int] = []
var _k: int = 5
var _num_points: int = 200
var _converged: bool = false

func get_name() -> String:
	return "K-Means"

func get_background_color() -> Color:
	return Color(0.02, 0.02, 0.04)

func get_initial_steps() -> int:
	return 2

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_converged = false

	# Generate clustered random points
	_points.clear()
	_assignments.clear()
	for i in range(_num_points):
		_points.append(Vector2(randf() * width, randf() * height))
		_assignments.append(0)

	# Random initial centroids
	_centroids.clear()
	_centroid_colors.clear()
	for i in range(_k):
		_centroids.append(Vector2(randf() * width, randf() * height))
		var hue = float(i) / float(_k)
		_centroid_colors.append(Color.from_hsv(hue, 0.7, 0.8))

	_render(img)

func step(img: Image, _step_index: int) -> bool:
	if _converged:
		return false

	# Assignment step
	var changed = false
	for i in range(_points.size()):
		var min_dist = INF
		var best_k = 0
		for j in range(_k):
			var dist = _points[i].distance_squared_to(_centroids[j])
			if dist < min_dist:
				min_dist = dist
				best_k = j
		if _assignments[i] != best_k:
			_assignments[i] = best_k
			changed = true

	# Update step — move centroids to cluster means
	for j in range(_k):
		var sum = Vector2.ZERO
		var count = 0
		for i in range(_points.size()):
			if _assignments[i] == j:
				sum += _points[i]
				count += 1
		if count > 0:
			_centroids[j] = sum / float(count)

	if not changed:
		_converged = true

	_render(img)
	return true

func _render(img: Image) -> void:
	img.fill(get_background_color())

	# Draw points colored by assignment
	for i in range(_points.size()):
		var p = _points[i]
		var c = _centroid_colors[_assignments[i]] * 0.6
		set_pixel_safe(img, int(p.x), int(p.y), c)
		# Make points 2px for visibility
		set_pixel_safe(img, int(p.x) + 1, int(p.y), c)
		set_pixel_safe(img, int(p.x), int(p.y) + 1, c)

	# Draw centroids bright and large
	for j in range(_k):
		var cx = int(_centroids[j].x)
		var cy = int(_centroids[j].y)
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				set_pixel_safe(img, cx + dx, cy + dy, Color.WHITE)
		# Inner color
		set_pixel_safe(img, cx, cy, _centroid_colors[j])
