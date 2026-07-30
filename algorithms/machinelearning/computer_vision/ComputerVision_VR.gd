extends Node3D

# @identity
# essence: output(x,y) = Σ kernel(i,j) · image(x+i, y+j) — convolution as local pattern matching
# desire: slide a kernel across an image with your hands, watch edges and features materialize
# critical_parameter: kernel weights — Sobel detects edges, Gaussian blurs, Sharpen enhances
# triggers: painting pixels changes the input image; applying different filters reveals different truths about the same data
# emerges: the realization that "seeing" is not passive — it requires a choice of what to look for
# needs: VR pixel painting [has conceptual], grabbable filter kernels [has], sliding kernel animation [has]
# relationships: unlocks convolutional_neural_networks_cnns_vr (learned kernels vs hand-designed); depends on neural_networks_vr (feature hierarchy)
# truth: every act of perception is a convolution — a commitment to which local patterns matter

# VR-Reimagined Computer Vision
# Interactive image processing with spatial convolution filters
# Real-time edge detection, feature extraction, and object detection

@export_group("VR Scale")
@export var image_canvas_size: float = 4.0  # Size of image plane
@export var pixel_size: float = 0.2  # Individual pixel cube size
@export var filter_size: float = 0.3  # Convolution kernel display size
@export var feature_map_spacing: float = 1.5  # Space between feature maps

@export_group("Image Processing")
@export var image_resolution: int = 16  # 16x16 pixel grid (for performance)
@export var num_feature_maps: int = 4  # Number of detected features
@export var edge_threshold: float = 0.5  # Edge detection sensitivity

@export_group("Filters")
@export var show_sobel_filter: bool = true
@export var show_gaussian_blur: bool = true
@export var show_sharpen_filter: bool = true
@export var animate_convolution: bool = true

@export_group("Interactive Elements")
@export var enable_pixel_painting: bool = true
@export var enable_filter_grabbing: bool = true
@export var enable_object_detection: bool = true
@export var show_sliding_kernel: bool = true

# ── Stage-2 DNA axis ─────────────────────────────────────────────────────────
@export_group("Detection DNA")

## detection — what the detector ASSERTS about an image that never changes. The
## 16 x 16 input pattern, the Sobel edge map and the four feature columns are
## identical at every value; only the claim laid over them moves. That is the whole
## point of this artifact: the claim here is a string constant with a percentage
## typed after it, so the detector can be made confidently wrong without touching
## one value of its evidence.
##
##   named     the shipped claim. Two wire boxes on the 4.0 x 4.0 m detection
##             canvas — 1.5 x 1.5 m captioned "Circle: 92%", 1.0 x 1.0 m captioned
##             "Cross: 85%" — sitting over the region where the circle and the
##             cross actually are. Hard-coded literals, not computations.
##   invented  the same two box sizes moved to the canvas's empty upper corners,
##             reading "Person: 97%" and "Vehicle: 94%". Two confident detections
##             of blank pixels on an image that has not changed by one value.
##   swarm     the canvas tiled with 36 boxes of 0.55 m at 0.65 m pitch, every one
##             of them a claim in the 30-50 percent band, captioned once by a
##             roll-up plate above the canvas rather than 36 times over. The
##             detector that hedges everywhere rather than commit anywhere.
##   whole     one box on the full 4.0 x 4.0 m canvas edge, captioned
##             "Image: 51%": technically a detection, structurally a refusal, and
##             the frame a great many real systems actually return.
##   bare      no boxes at all. The detection station keeps its station label and
##             its empty air while the input canvas, the four 0.3 m filter tools,
##             the edge canvas, the four feature columns and the 3.0 x 4.0 m
##             control panel all still stand across the 24 m workshop — a refusal
##             to name inside a room that is otherwise full, so the frame is not
##             blank and the value cannot be misread as inert.
##
## enable_object_detection is left alone on purpose. It early-returns the ENTIRE
## station, label and all, and `bare` must keep the station while dropping only the
## boxes — otherwise the axis and the flag would be two ways of saying one thing.
##
## REFUSED as axes: animate_convolution and show_sliding_kernel. The sliding 3 x 3
## kernel window is a position on a timeline and a still catches it in an arbitrary
## cell. Varying the input pattern was considered and rejected as a second axis —
## changing what is there weakens the point, which is that the claim can be wrong
## while the world stays still.
@export_enum("named", "invented", "swarm", "whole", "bare") var detection: String = "named"

## Allow-list for the axis. A value outside it is a typo in a map token and must
## fall back to the shipped claim rather than strand a placement with an empty
## detection station.
const DETECTIONS: PackedStringArray = ["named", "invented", "swarm", "whole", "bare"]

# ── Caption placement (metres) ───────────────────────────────────────────────
# commons/grid/LabelFramer.gd turns every hanging Label3D into an OPAQUE anthracite
# panel with a bezel at spawn, so where a Label3D sits is where a solid plate sits.
# At font 20 / pixel_size 0.005 a caption is about 0.10 m of text and 0.55 m wide,
# so the plate lands near 0.65 x 0.17 m and its bezel near 0.68 x 0.20 m.

## The shipped caption position was `pos_y + scale_y / 2 + 0.3` — 0.30 m up INSIDE
## the box it names, which put a 0.65 x 0.17 m plate across the box's left rail and
## blacked out roughly 0.18 m of a 0.02 m cylinder. CAPTION_LIFT places the plate
## wholly ABOVE the box's own top rail instead: 0.24 m of lift clears the rail's
## outer face by about 0.13 m of air.
const CAPTION_LIFT: float = 0.24

## Second tier, for a caption whose plate would otherwise cross ANOTHER box's rail.
## The shipped pair is concentric — the 1.0 m Cross box sits inside the 1.5 m Circle
## box — so a Cross caption lifted only above its own top rail (y = 0.74) would lie
## across 0.58 m of the Circle box's top rail at y = 0.75. It goes one tier higher.
## 0.34 m leaves about 0.12 m of air between the two bezels, and the two can never
## merge into one nameplate in any case: each caption lives in its own bbox
## container, and LabelFramer only merges labels that share a parent.
const CAPTION_TIER: float = 0.34

# ── swarm layout (metres) ────────────────────────────────────────────────────
const SWARM_COLS: int = 6
const SWARM_ROWS: int = 6
const SWARM_BOX_M: float = 0.55
const SWARM_PITCH_M: float = 0.65

## Roll-up plate height: 0.20 m above the top row of boxes (whose top edge lands at
## 1.90 m) and about 0.15 m below the station label's own plate.
const SWARM_ROLLUP_Y: float = 2.30

## Confidence band for the swarm — 0.30 to 0.50 in 21 integer steps, walked with a
## stride coprime to 21 so every step in the band appears exactly once per 21 boxes.
## Arithmetic, not RNG: there is no randf() anywhere in this file and the axis does
## not introduce one.
const SWARM_CONF_MIN: float = 0.30
const SWARM_CONF_STEPS: int = 21
const SWARM_CONF_STRIDE: int = 5

# Image data
var input_image: Array = []  # 2D array of grayscale values
var edge_map: Array = []
var feature_maps: Array = []

# Visual elements
var pixel_meshes: Array = []  # MeshInstance3D for each pixel
var edge_pixels: Array = []
var feature_visualizations: Array = []
var bounding_boxes: Array = []

# Convolution kernels
var sobel_x: Array = [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]]
var sobel_y: Array = [[-1, -2, -1], [0, 0, 0], [1, 2, 1]]
var gaussian: Array = [[1, 2, 1], [2, 4, 2], [1, 2, 1]]  # Will be normalized
var sharpen: Array = [[0, -1, 0], [-1, 5, -1], [0, -1, 0]]

# Animation
var time: float = 0.0
var convolution_progress: float = 0.0
var current_filter_pos: Vector2i = Vector2i(0, 0)

# Kernel visualization
var kernel_window: Node3D

## True once the synchronous build has run. apply_grid_config must not rebuild
## before it, or the artifact would build twice.
var _built: bool = false

## Only the nodes THIS script parents to self. _rebuild_now frees these and nothing
## else — by then get_children() also holds LabelFramer's plates and anything else
## the grid attached, and freeing those strips the artifact of furniture it does not
## own.
var _owned: Array[Node] = []

## Non-geometry key from curation_station.gd, applied in place to live materials and
## honoured by every later build.
var _emissive: bool = true

func _ready() -> void:
	print("[ComputerVision_VR] Initializing computer vision workspace")
	_build_all()
	_built = true

## The whole workshop, built SYNCHRONOUSLY from @export values alone. The DNA sweep
## sets the swept exports, adds the node to the tree and photographs frame one, and
## the grid's auto-grounder measures the subtree AABB in that same frame — a
## deferred build would hand both of them an empty subtree.
func _build_all() -> void:
	_initialize_image_data()
	_create_input_canvas()
	_create_filter_toolkit()
	_create_edge_detection_area()
	_create_feature_extraction_area()
	_create_object_detection_area()
	_create_convolution_visualizer()
	_create_control_panel()
	_create_info_panels()

## add_child + track. Every node this script hangs on self goes through here so
## _rebuild_now knows exactly what it may free.
func _own(node: Node) -> void:
	add_child(node)
	_owned.append(node)

func _process(delta: float) -> void:
	time += delta

	if animate_convolution:
		convolution_progress += delta * 0.5
		if convolution_progress >= 1.0:
			convolution_progress = 0.0
			_step_convolution()

	_update_pixel_display(delta)
	_animate_kernel_window(delta)
	_animate_features(delta)

func _initialize_image_data() -> void:
	"""Initialize input image with sample pattern"""
	for y in range(image_resolution):
		var row = []
		for x in range(image_resolution):
			# Create a simple test pattern (cross + circle)
			var center = image_resolution / 2.0
			var dist = sqrt(pow(x - center, 2) + pow(y - center, 2))

			var value = 0.0
			# Circle
			if dist < image_resolution / 3.0:
				value = 0.8
			# Cross
			if abs(x - center) < 2 or abs(y - center) < 2:
				value = 1.0

			row.append(value)
		input_image.append(row)

	# Initialize edge map
	edge_map = _apply_edge_detection(input_image)

	# Initialize feature maps
	for i in range(num_feature_maps):
		feature_maps.append([])

func _create_input_canvas() -> void:
	"""Create interactive input image canvas"""
	var canvas_container = Node3D.new()
	canvas_container.name = "InputCanvas"
	canvas_container.position = Vector3(-8.0, 0, 0)
	_own(canvas_container)

	# Canvas label
	var label = Label3D.new()
	label.text = "INPUT IMAGE\nPaint pixels with hand"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.9, 0.9, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, image_canvas_size / 2.0 + 1.0, 0)
	canvas_container.add_child(label)

	# Create pixel grid
	for y in range(image_resolution):
		var row_meshes = []
		for x in range(image_resolution):
			var pixel = _create_pixel(x, y, input_image[y][x])
			canvas_container.add_child(pixel)
			row_meshes.append(pixel)
		pixel_meshes.append(row_meshes)

func _create_pixel(x: int, y: int, value: float) -> MeshInstance3D:
	"""Create a single pixel cube"""
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(pixel_size, pixel_size, pixel_size)
	mesh.mesh = box

	# Position in grid
	var grid_size = image_canvas_size
	var px = (float(x) / image_resolution - 0.5) * grid_size
	var py = (float(y) / image_resolution - 0.5) * grid_size
	mesh.position = Vector3(px, py, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(value, value, value)
	mat.emission_enabled = _emissive
	mat.emission = Color(value, value, value)
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat

	return mesh

func _create_filter_toolkit() -> void:
	"""Create grabbable filter objects"""
	var toolkit_container = Node3D.new()
	toolkit_container.name = "FilterToolkit"
	toolkit_container.position = Vector3(-8.0, -image_canvas_size / 2.0 - 2.0, 0)
	_own(toolkit_container)

	# Toolkit label
	var label = Label3D.new()
	label.text = "FILTER TOOLKIT\nGrab to apply"
	label.font_size = 42
	label.outline_size = 10
	label.modulate = Color(0.3, 0.9, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.0, 0)
	toolkit_container.add_child(label)

	# Create filter buttons
	var filters = [
		{"name": "Sobel X", "color": Color(0.9, 0.3, 0.3), "kernel": sobel_x},
		{"name": "Sobel Y", "color": Color(0.3, 0.9, 0.3), "kernel": sobel_y},
		{"name": "Gaussian", "color": Color(0.3, 0.3, 0.9), "kernel": gaussian},
		{"name": "Sharpen", "color": Color(0.9, 0.9, 0.3), "kernel": sharpen}
	]

	for i in range(filters.size()):
		var filter_data = filters[i]
		var filter_obj = _create_filter_object(filter_data, Vector3(i * 1.2 - 1.8, 0, 0))
		toolkit_container.add_child(filter_obj)

func _create_filter_object(filter_data: Dictionary, pos: Vector3) -> RigidBody3D:
	"""Create a grabbable filter tool"""
	var body = RigidBody3D.new()
	body.name = "Filter_" + filter_data.name.replace(" ", "_")
	body.position = pos
	body.gravity_scale = 0.0

	# Filter mesh (3x3 grid showing kernel)
	var grid_container = Node3D.new()
	body.add_child(grid_container)

	var kernel = filter_data.kernel
	for ky in range(3):
		for kx in range(3):
			var cell = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(filter_size / 3.5, filter_size / 3.5, 0.05)
			cell.mesh = box

			var value = kernel[ky][kx]
			var normalized_value = (value + 2) / 4.0  # Normalize to 0-1 range
			var mat = StandardMaterial3D.new()
			mat.albedo_color = filter_data.color * normalized_value
			mat.emission_enabled = _emissive
			mat.emission = filter_data.color * normalized_value
			mat.emission_energy_multiplier = 0.8
			mat.metallic = 0.0
			mat.roughness = 1.0
			cell.material_override = mat

			cell.position = Vector3(
				(kx - 1) * filter_size / 3.0,
				(ky - 1) * filter_size / 3.0,
				0
			)
			grid_container.add_child(cell)

	# Collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(filter_size, filter_size, 0.1)
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable
	if enable_filter_grabbing:
		body.collision_layer = 1 | (1 << 20)
		body.collision_mask = 1

	# Label
	var label = Label3D.new()
	label.text = filter_data.name
	label.font_size = 24
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, filter_size / 2.0 + 0.3, 0)
	body.add_child(label)

	return body

func _create_edge_detection_area() -> void:
	"""Create edge detection visualization area"""
	var edge_container = Node3D.new()
	edge_container.name = "EdgeDetection"
	edge_container.position = Vector3(-2.0, 0, 0)
	_own(edge_container)

	# Label
	var label = Label3D.new()
	label.text = "EDGE DETECTION\nSobel Filter"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.9, 0.3, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, image_canvas_size / 2.0 + 1.0, 0)
	edge_container.add_child(label)

	# Create edge pixel grid
	for y in range(image_resolution):
		var row_meshes = []
		for x in range(image_resolution):
			var edge_value = edge_map[y][x]
			var pixel = _create_pixel(x, y, edge_value)
			edge_container.add_child(pixel)
			row_meshes.append(pixel)
		edge_pixels.append(row_meshes)

func _create_feature_extraction_area() -> void:
	"""Create feature map visualization"""
	var feature_container = Node3D.new()
	feature_container.name = "FeatureExtraction"
	feature_container.position = Vector3(4.0, 0, 0)
	_own(feature_container)

	# Label
	var label = Label3D.new()
	label.text = "FEATURE MAPS\nLearned Patterns"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.3, 0.9, 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, image_canvas_size / 2.0 + 1.5, 0)
	feature_container.add_child(label)

	# Create feature map columns
	for i in range(num_feature_maps):
		var feature_col = Node3D.new()
		feature_col.name = "FeatureMap_%d" % i
		feature_col.position = Vector3(i * feature_map_spacing - (num_feature_maps - 1) * feature_map_spacing / 2.0, 0, 0)
		feature_container.add_child(feature_col)

		# Feature spheres
		var num_features = 5 + i * 2
		var feature_spheres = []
		for f in range(num_features):
			var sphere = MeshInstance3D.new()
			var sphere_mesh = SphereMesh.new()
			sphere_mesh.radius = 0.15
			sphere_mesh.height = 0.3
			sphere.mesh = sphere_mesh

			var mat = StandardMaterial3D.new()
			var hue = float(i) / num_feature_maps
			var color = Color.from_hsv(hue, 0.8, 0.9)
			mat.albedo_color = color
			mat.emission_enabled = _emissive
			mat.emission = color
			mat.emission_energy_multiplier = 1.0
			mat.metallic = 0.0
			mat.roughness = 1.0
			sphere.material_override = mat

			var angle = float(f) / num_features * TAU
			var radius = 0.8
			sphere.position = Vector3(
				cos(angle) * radius,
				sin(angle) * radius,
				0
			)

			feature_col.add_child(sphere)
			feature_spheres.append(sphere)

		feature_visualizations.append(feature_spheres)

func _create_object_detection_area() -> void:
	"""Create object detection bounding box visualization"""
	if not enable_object_detection:
		return

	var detection_container = Node3D.new()
	detection_container.name = "ObjectDetection"
	detection_container.position = Vector3(10.0, 0, 0)
	_own(detection_container)

	# Label
	var label = Label3D.new()
	label.text = "OBJECT DETECTION\nBounding Boxes"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.9, 0.5, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, image_canvas_size / 2.0 + 1.0, 0)
	detection_container.add_child(label)

	# THE CLAIM. `detection` chooses which literal the detector asserts, and at
	# swarm generates one. Note what does NOT branch: _initialize_image_data ran
	# four functions earlier and its 16 x 16 pattern is byte-identical at every
	# value, as is the Sobel edge map beside it. Only the assertion moves.
	var bbox_data: Array = _bbox_data_for(detection)

	for data in bbox_data:
		var bbox = _create_bounding_box(data)
		detection_container.add_child(bbox)
		bounding_boxes.append(bbox)

	# 36 captions would bury the 36 boxes they name. One plate speaks for all of them.
	if detection == "swarm":
		detection_container.add_child(_create_swarm_rollup(bbox_data.size()))


# ── The five claims ──────────────────────────────────────────────────────────
# Each returns a list of bounding-box specs in IMAGE CELL coordinates: `pos` is the
# lower-left cell, `size` is a count of cells. That is the same coordinate system
# _initialize_image_data draws the circle and the cross in, so "over the shape" and
# "over blank pixels" are statements about one grid rather than two.

func _bbox_data_for(mode: String) -> Array:
	match mode:
		"invented":
			return _bbox_invented()
		"swarm":
			return _bbox_swarm()
		"whole":
			return _bbox_whole()
		"bare":
			# A refusal to name. The station and its label stand; nothing is claimed.
			return []
	return _bbox_named()


## The shipped literal, geometry untouched: cells 5..11 for the circle at 92 percent
## and 6..10 for the cross at 85 percent, both centred on the pattern. The two
## captions move — out of the boxes they used to be printed across, and above them.
func _bbox_named() -> Array:
	var circle_top: float = _cell_to_m(5.0) + _span_to_m(6.0)  # 0.75 m
	var tier_one: float = circle_top + CAPTION_LIFT             # 0.99 m
	return [
		{"pos": Vector2(5, 5), "size": Vector2(6, 6),
			"label": "Circle", "confidence": 0.92, "caption_y": tier_one},
		# One tier higher, at 1.33 m. This box is nested INSIDE the circle box, so
		# its own top rail is not the highest rail beneath its caption.
		{"pos": Vector2(6, 6), "size": Vector2(4, 4),
			"label": "Cross", "confidence": 0.85, "caption_y": tier_one + CAPTION_TIER}
	]


## The same two box sizes, moved off the pattern and into the upper corners, naming
## two things this image does not contain. The image has not changed by one value.
##
## HONEST NOTE ON CLEARANCE. The brief asks for 1.4 m of blank pixels around each
## box and this particular image cannot give it. _initialize_image_data's cross is
## not a central plus: `abs(x - center) < 2 or abs(y - center) < 2` lights cells
## 7..9 of EVERY row and EVERY column, so the arms run edge to edge, and the circle
## is a disc of radius 5.33 cells about the centre. 119 of the 256 cells are lit and
## the largest fully dark square left in a corner is 4 cells, 1.0 m — so no 1.5 m
## box anywhere on this canvas can stand 1.4 m off the pattern. Measured instead:
##   Vehicle, 1.0 m, cells 12..16 square, top-right — 0 of 16 cells lit,
##            nearest lit cell 0.25 m away.
##   Person,  1.5 m, cells 0..6 x 10..16, top-left — 5 of 36 cells lit, where its
##            inner corner grazes the disc's rim; nearest lit cell 0.
## Against `named`, where both boxes are 36 of 36 and 16 of 16 lit, that is still
## the statement the axis exists to make. Shrinking the boxes to buy the 1.4 m would
## have cost the "same two box sizes" the comparison depends on.
func _bbox_invented() -> Array:
	return [
		{"pos": Vector2(0, 10), "size": Vector2(6, 6),
			"label": "Person", "confidence": 0.97},
		{"pos": Vector2(12, 12), "size": Vector2(4, 4),
			"label": "Vehicle", "confidence": 0.94}
	]


## The hedge. 36 boxes at 0.55 m on a 0.65 m pitch — 3.80 m of tiling centred on a
## 4.0 m canvas, 0.10 m of air between neighbours so none of them overlaps — every
## one carrying a claim in the 30-50 percent band and none of them carrying a
## caption. Fully determined by index: no RNG, no frame count, no clock.
func _bbox_swarm() -> Array:
	var out: Array = []
	var size_cells: float = _m_to_span(SWARM_BOX_M)
	var span: float = SWARM_PITCH_M * float(SWARM_COLS - 1) + SWARM_BOX_M  # 3.80 m
	var origin: float = -span * 0.5                                        # -1.90 m
	for r in range(SWARM_ROWS):
		for c in range(SWARM_COLS):
			var idx: int = r * SWARM_COLS + c
			var step: int = (idx * SWARM_CONF_STRIDE) % SWARM_CONF_STEPS
			out.append({
				"pos": Vector2(
					_m_to_cell(origin + float(c) * SWARM_PITCH_M),
					_m_to_cell(origin + float(r) * SWARM_PITCH_M)),
				"size": Vector2(size_cells, size_cells),
				"label": "Region",
				"confidence": SWARM_CONF_MIN + float(step) * 0.01,
				# 0.78 m diagonal, under the 1.0 m the brief sets as the bar for a
				# caption of a box's own. The roll-up plate speaks for all 36.
				"caption": false
			})
	return out


## One box on the full canvas edge at 51 percent: technically a detection,
## structurally a refusal.
func _bbox_whole() -> Array:
	return [{
		"pos": Vector2(0, 0),
		"size": Vector2(image_resolution, image_resolution),
		"label": "Image", "confidence": 0.51
	}]


## The swarm's single caption. Its own container, so LabelFramer's stack rule (same
## parent, same column, small gap) cannot fuse this plate with the station label
## 0.70 m above it.
func _create_swarm_rollup(count: int) -> Node3D:
	var holder := Node3D.new()
	holder.name = "SwarmRollup"
	var label := Label3D.new()
	label.text = "%d REGIONS\n30-50%% confidence" % count
	label.font_size = 24
	label.outline_size = 6
	label.modulate = Color(0.9, 0.5, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, SWARM_ROLLUP_Y, 0.1)
	holder.add_child(label)
	return holder


# ── Cell / metre conversions ─────────────────────────────────────────────────
# Identical arithmetic to _create_pixel, kept in one place so a box and a pixel can
# never disagree about where cell 8 is.

## Cell index -> metres in the canvas's own centred frame.
func _cell_to_m(cell: float) -> float:
	return (cell / float(image_resolution) - 0.5) * image_canvas_size

## Cell count -> metres.
func _span_to_m(cells: float) -> float:
	return cells / float(image_resolution) * image_canvas_size

func _m_to_cell(m: float) -> float:
	return (m / image_canvas_size + 0.5) * float(image_resolution)

func _m_to_span(m: float) -> float:
	return m / image_canvas_size * float(image_resolution)

func _create_bounding_box(data: Dictionary) -> Node3D:
	"""Create a bounding box visualization"""
	var bbox_container = Node3D.new()

	# Box edges
	var edges = [
		[Vector3(0, 0, 0), Vector3(1, 0, 0)],
		[Vector3(1, 0, 0), Vector3(1, 1, 0)],
		[Vector3(1, 1, 0), Vector3(0, 1, 0)],
		[Vector3(0, 1, 0), Vector3(0, 0, 0)]
	]

	var scale_x: float = _span_to_m(float(data.size.x))
	var scale_y: float = _span_to_m(float(data.size.y))
	var pos_x: float = _cell_to_m(float(data.pos.x))
	var pos_y: float = _cell_to_m(float(data.pos.y))

	for edge in edges:
		var line = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.02
		cylinder.bottom_radius = 0.02
		var length = (edge[1] - edge[0]).length() * max(scale_x, scale_y)
		cylinder.height = length
		line.mesh = cylinder

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.5, 0.3)
		mat.emission_enabled = _emissive
		mat.emission = Color(0.9, 0.5, 0.3)
		mat.emission_energy_multiplier = 1.2
		mat.metallic = 0.0
		mat.roughness = 1.0
		line.material_override = mat

		var mid = (edge[0] + edge[1]) / 2.0
		line.position = Vector3(mid.x * scale_x + pos_x, mid.y * scale_y + pos_y, 0.1)

		var direction = (edge[1] - edge[0]).normalized()
		if direction.length() > 0.01:
			line.look_at(line.position + Vector3(direction.x, direction.y, 0), Vector3.UP)
			line.rotate_object_local(Vector3.RIGHT, PI / 2.0)

		bbox_container.add_child(line)

	# Caption. Every one of these becomes an opaque plate at spawn, so it hangs
	# ABOVE its own top rail — never in the box, which is where the shipped version
	# put it (pos_y + scale_y / 2 + 0.3 landed 0.30 m up inside a 1.5 m box and
	# blacked out its left rail). `caption_y`, when the claim supplies one, lifts a
	# caption clear of a LARGER box it is nested inside; `caption: false` drops it
	# entirely, which is how the swarm avoids captioning 36 boxes into invisibility.
	if bool(data.get("caption", true)):
		var label = Label3D.new()
		label.text = "%s: %.0f%%" % [data.label, data.confidence * 100]
		label.font_size = 20
		label.outline_size = 6
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		var cap_y: float = float(data.get("caption_y", pos_y + scale_y + CAPTION_LIFT))
		label.position = Vector3(pos_x, cap_y, 0.1)
		bbox_container.add_child(label)

	return bbox_container

func _create_convolution_visualizer() -> void:
	"""Create sliding kernel window animation"""
	if not show_sliding_kernel:
		return

	kernel_window = Node3D.new()
	kernel_window.name = "KernelWindow"
	_own(kernel_window)

	# 3x3 kernel outline
	var outline = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(pixel_size * 3.2, pixel_size * 3.2, 0.05)
	outline.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.3, 0.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# This box is alpha 0 and unshaded: its emission is the only thing it has to
	# show, so `emissive: false` legitimately turns it into an unlit ghost.
	mat.emission_enabled = _emissive
	mat.emission = Color(0.9, 0.9, 0.3)
	mat.emission_energy_multiplier = 1.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.material_override = mat

	kernel_window.add_child(outline)

	# Position at input canvas
	kernel_window.position = Vector3(-8.0, 0, 0.2)

func _create_control_panel() -> void:
	"""Create VR control panel"""
	var controls = Node3D.new()
	controls.name = "ControlPanel"
	controls.position = Vector3(13.0, 0, 0)
	_own(controls)

	# Panel background
	var panel = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.0, 4.0, 0.1)
	panel.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.3, 0.95)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.0
	mat.roughness = 1.0
	panel.material_override = mat
	controls.add_child(panel)

	# Title
	var title = Label3D.new()
	title.text = "COMPUTER VISION\nPIPELINE"
	title.font_size = 56
	title.outline_size = 12
	title.position = Vector3(0, 1.6, 0.1)
	controls.add_child(title)

	# Info
	var info = Label3D.new()
	info.text = "Resolution: %dx%d\nFilters: 4\nFeatures: %d" % [image_resolution, image_resolution, num_feature_maps]
	info.font_size = 32
	info.outline_size = 8
	info.position = Vector3(0, 0.3, 0.1)
	controls.add_child(info)

func _create_info_panels() -> void:
	"""Create educational info panels"""
	# Convolution explanation
	_create_info_panel(
		Vector3(-8.0, image_canvas_size / 2.0 + 2.5, -2.0),
		"CONVOLUTION\nSliding window operation\nKernel Ã— Image = Feature\nLocal pattern detection",
		Color(0.9, 0.9, 0.3)
	)

	# Edge detection
	_create_info_panel(
		Vector3(-2.0, image_canvas_size / 2.0 + 2.5, -2.0),
		"SOBEL FILTER\nComputes gradients\nDetects edges and boundaries\nFoundation of CV",
		Color(0.9, 0.3, 0.3)
	)

	# Features
	_create_info_panel(
		Vector3(4.0, image_canvas_size / 2.0 + 3.0, -2.0),
		"FEATURE EXTRACTION\nHierarchical patterns\nLow to high level features\nLearn ed representations",
		Color(0.3, 0.9, 0.5)
	)

func _create_info_panel(pos: Vector3, text: String, color: Color) -> void:
	"""Create floating info panel"""
	var label = Label3D.new()
	label.text = text
	label.font_size = 28
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	# Children of the root, at three different x, so LabelFramer buckets them into
	# three separate columns and none of them can merge with a station label.
	_own(label)

func _update_pixel_display(_delta) -> void:
	"""Update pixel visualization"""
	# Update input pixels
	for y in range(image_resolution):
		for x in range(image_resolution):
			var pixel = pixel_meshes[y][x]
			var value = input_image[y][x]

			# Pulse effect
			var pulse = 1.0 + sin(time * 2.0 + x * 0.1 + y * 0.1) * 0.1
			pixel.scale = Vector3.ONE * pulse

			# Update color
			pixel.material_override.albedo_color = Color(value, value, value)
			pixel.material_override.emission = Color(value, value, value)

	# Update edge pixels
	for y in range(image_resolution):
		for x in range(image_resolution):
			var pixel = edge_pixels[y][x]
			var value = edge_map[y][x]

			pixel.material_override.albedo_color = Color(value, value * 0.3, value * 0.3)
			pixel.material_override.emission = Color(value, value * 0.3, value * 0.3)

func _animate_kernel_window(_delta) -> void:
	"""Animate sliding convolution kernel"""
	if not show_sliding_kernel or not kernel_window:
		return

	# Move kernel across image
	var grid_size = image_canvas_size
	var px = (float(current_filter_pos.x) / image_resolution - 0.5) * grid_size
	var py = (float(current_filter_pos.y) / image_resolution - 0.5) * grid_size
	kernel_window.position = Vector3(-8.0 + px, py, 0.2)

func _animate_features(_delta) -> void:
	"""Animate feature visualizations"""
	for i in range(feature_visualizations.size()):
		var features = feature_visualizations[i]
		for f in range(features.size()):
			var sphere = features[f]
			var pulse = 1.0 + sin(time * 2.5 + i + f * 0.5) * 0.2
			sphere.scale = Vector3.ONE * pulse

func _step_convolution() -> void:
	"""Step convolution animation"""
	current_filter_pos.x += 1
	if current_filter_pos.x >= image_resolution - 2:
		current_filter_pos.x = 1
		current_filter_pos.y += 1
		if current_filter_pos.y >= image_resolution - 2:
			current_filter_pos.y = 1

func _apply_edge_detection(img: Array) -> Array:
	"""Apply Sobel edge detection"""
	var result = []
	for y in range(image_resolution):
		var row = []
		for x in range(image_resolution):
			if x <= 0 or x >= image_resolution - 1 or y <= 0 or y >= image_resolution - 1:
				row.append(0.0)
				continue

			# Apply Sobel kernels
			var gx = 0.0
			var gy = 0.0
			for ky in range(3):
				for kx in range(3):
					var pixel_val = img[y + ky - 1][x + kx - 1]
					gx += pixel_val * sobel_x[ky][kx]
					gy += pixel_val * sobel_y[ky][kx]

			var magnitude = sqrt(gx * gx + gy * gy)
			row.append(clamp(magnitude, 0.0, 1.0))
		result.append(row)
	return result

# Public API
func apply_filter(filter_name: String) -> void:
	"""Apply a filter to the input image"""
	print("[CV] Applying filter: ", filter_name)
	edge_map = _apply_edge_detection(input_image)

func set_pixel_value(x: int, y: int, value: float) -> void:
	"""Set a pixel value (for painting)"""
	if x >= 0 and x < image_resolution and y >= 0 and y < image_resolution:
		input_image[y][x] = clamp(value, 0.0, 1.0)
		edge_map = _apply_edge_detection(input_image)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## GridInteractablesComponent calls this via call_deferred, after _ready() and first
## in the deferred queue — so the build has already happened and this either changes
## nothing or rebuilds it. Map token: `#detection:invented`.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_detection: String = detection
	if config_data.has("detection"):
		detection = _pick_axis(str(config_data["detection"]), DETECTIONS, detection)

	# Non-geometry key, applied IN PLACE before the early returns below.
	# curation_station.gd hands EVERY artifact it curates {"emissive": false} one
	# line after framing its labels; that dict carries no axis key, so it must not
	# rebuild, and it must still bite. An accepted key that does nothing is the
	# failure this ordering exists to prevent.
	if config_data.has("emissive"):
		_emissive = _pick_bool(config_data["emissive"], _emissive)
		_apply_emissive(self)

	if not _built:
		return
	if detection == before_detection:
		return
	_rebuild_now()
	print("[ComputerVision_VR] Config applied - detection=%s" % [detection])


## Accept an axis value only if it names something this artifact actually builds. A
## typo in a map token has to fall back to the shipped claim — a half-recognised
## value would strand a placement with a detection station and no detection.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Map JSON hands booleans through as strings as often as not.
func _pick_bool(raw: Variant, fallback: bool) -> bool:
	if typeof(raw) == TYPE_STRING:
		var s: String = str(raw).to_lower().strip_edges()
		if s in ["false", "0", "off", "no"]:
			return false
		if s in ["true", "1", "on", "yes"]:
			return true
		return fallback
	if typeof(raw) == TYPE_BOOL or typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
		return bool(raw)
	return fallback


## Rebuild the workshop for a new axis value. SYNCHRONOUS and inline: a deferred
## rebuild that removes children first leaves the grid's auto-grounder measuring a
## zero AABB and bailing out, which drops the artifact through the floor.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()

	# Cached references into the subtree just freed, plus the arrays
	# _initialize_image_data APPENDS to — left alone they would double every row on
	# the second build and _update_pixel_display would index a freed pixel.
	pixel_meshes.clear()
	edge_pixels.clear()
	feature_visualizations.clear()
	bounding_boxes.clear()
	input_image.clear()
	feature_maps.clear()
	edge_map = []
	kernel_window = null

	# Animation state too, so a rebuilt workshop is pixel-identical to a first build
	# of the same value rather than one carrying a stale phase.
	time = 0.0
	convolution_progress = 0.0
	current_filter_pos = Vector2i(0, 0)

	_build_all()


## Toggle emission on every material THIS script created, in place. material_override
## is the only material any build path here sets. LabelFramer's plates are skipped by
## their own meta marker — the caption furniture is not this artifact's body.
func _apply_emissive(node: Node) -> void:
	if node is MeshInstance3D and not node.has_meta("label_plate"):
		var mat: Material = (node as MeshInstance3D).material_override
		if mat is StandardMaterial3D:
			(mat as StandardMaterial3D).emission_enabled = _emissive
	for c in node.get_children():
		_apply_emissive(c)
