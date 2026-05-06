# @identity
# essence: a 128×128 Gray-Scott reaction-diffusion simulation displayed on a 3D mesh plane — two chemical species U and V diffuse at different rates, react, and self-organize into spots, stripes, and branching coral-like patterns from uniform random noise
# desire: to show that pattern is a property of dynamics, not of design — the spots and stripes are not drawn; they are consequences of how two competing processes balance across a field
# critical_parameter: feed/kill ratio — small changes cross phase boundaries, switching the system from spots to stripes to mazes to corals; different regions of (feed, kill) parameter space are literally different morphological regimes
# triggers: _ready initializes U/V arrays, creates ImageTexture on a flat MeshInstance3D, starts movement_timer; each tick runs Laplacian convolution + Gray-Scott reaction term on every cell, then pushes the result to the texture
# emerges: the simulation is sensitive to initial conditions — same feed/kill with different random seeds produces morphologically identical but spatially unique patterns; the "species" is the parameter pair, not the seed
# needs: VR controls for live feed/kill parameter tuning [missing — currently export vars only]; apply_grid_config [missing]
# relationships: turing_pattern_generator also implements Gray-Scott but with VR controls; queer_morphology_specimen grows morphological forms using different rules; all three appear in the morphogenesis "Pattern from Noise" map
# truth: you don't need a blueprint — the pattern that looks designed emerges from two numbers: how fast each chemical diffuses relative to the other; Turing's morphogenesis is not a metaphor, it is a mechanism

extends Node3D

# ==============================
# CONFIGURATION PARAMETERS
# ==============================
@export var width: int = 128
@export var height: int = 128

# Diffusion constants for U and V
@export var Du: float = 0.16
@export var Dv: float = 0.08

# Reaction parameters (feed & kill rates)
@export var feed: float = 0.035
@export var kill: float = 0.065

# Time step for each PDE iteration
@export var interval: float = 0.8

# Reset after 300 seconds (optional)
@export var reset_interval: float = 300.0

# Background color for initial fill
@export var background_color: Color = Color(0, 0, 0, 1)

# Optional label text
@export var label_text: String = ""

# We'll store two fields: U and V, each a flattened 2D array
var U = PackedFloat32Array()
var V = PackedFloat32Array()

# Scratch arrays reused every tick to avoid allocations
var _U_next = PackedFloat32Array()
var _V_next = PackedFloat32Array()

# The image and texture we update each frame
var img: Image
var texture: ImageTexture

# Timers
var movement_timer: Timer
var reset_timer: Timer

# References in your scene tree
@onready var label3d = $id_info_Label3D
@onready var mesh_instance: MeshInstance3D = $ReactionDiffusionPlanMesh

# ==============================
# INITIALIZATION
# ==============================
func _ready() -> void:
	if mesh_instance == null:
		push_error("MeshInstance3D not found!")
		return

	# 1) Resize the U, V, and scratch arrays
	var total = width * height
	U.resize(total)
	V.resize(total)
	_U_next.resize(total)
	_V_next.resize(total)

	# 2) Create an Image and fill it
	img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(background_color)
	
	# 3) Create a texture from this image
	texture = ImageTexture.create_from_image(img)

	# 4) Assign a unique material (no external helper needed)
	_assign_texture_to_mesh(mesh_instance, texture)

	# 5) Initialize U and V with a pattern (random or image based)
	_reset_fields()

	# 6) Create and start the timers
	movement_timer = Timer.new()
	movement_timer.wait_time = interval
	movement_timer.one_shot = false
	movement_timer.connect("timeout", Callable(self, "_on_Timer_timeout"))
	add_child(movement_timer)
	movement_timer.start()

	reset_timer = Timer.new()
	reset_timer.wait_time = reset_interval
	reset_timer.one_shot = false
	reset_timer.connect("timeout", Callable(self, "_on_Reset_Timer"))
	add_child(reset_timer)
	reset_timer.start()

	label3d.text = label_text

# ==============================
# ONE STEP OF REACTION–DIFFUSION
# ==============================
func _on_Timer_timeout() -> void:
	# For each cell, compute Laplacian and update into scratch arrays
	for y in range(height):
		for x in range(width):
			var idx = x + y * width
			var u = U[idx]
			var v = V[idx]

			# Laplacian approximations
			var lap_u = _laplacian(U, x, y)
			var lap_v = _laplacian(V, x, y)

			# Reaction terms for Gray-Scott
			var uvv = u * v * v
			var du = Du * lap_u - uvv + feed * (1.0 - u)
			var dv = Dv * lap_v + uvv - (feed + kill) * v

			# Update with a time step = interval
			_U_next[idx] = clamp(u + du * interval, 0.0, 1.0)
			_V_next[idx] = clamp(v + dv * interval, 0.0, 1.0)

	# Swap references (no allocation — just pointer swap)
	var tmp_u = U
	U = _U_next
	_U_next = tmp_u
	var tmp_v = V
	V = _V_next
	_V_next = tmp_v

	# Update the image with vibrant colors by mapping the difference between U and V to a hue
	for y in range(height):
		for x in range(width):
			var idx = x + y * width
			# Map the difference to a hue in the 0-1 range
			var hue = (U[idx] - V[idx] + 1.0) / 2.0
			# Use full saturation and brightness for vibrancy
			img.set_pixel(x, y, Color.from_hsv(hue, 1.0, 1.0, 1.0))
	texture.update(img)

# ==============================
# HELPER FUNCTIONS
# ==============================
# Simple material assignment
func _assign_texture_to_mesh(mesh_inst: MeshInstance3D, tex: Texture2D) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mesh_inst.material_override = mat

# Computes the 2D Laplacian with 4 neighbors (wrap-around)
func _laplacian(arr: PackedFloat32Array, x: int, y: int) -> float:
	var sum: float = 0.0
	sum += arr[_wrap_index(x - 1, y)]
	sum += arr[_wrap_index(x + 1, y)]
	sum += arr[_wrap_index(x, y - 1)]
	sum += arr[_wrap_index(x, y + 1)]
	sum -= arr[_wrap_index(x, y)] * 4.0
	return sum

# Toroidal wrap-around for edges
func _wrap_index(x: int, y: int) -> int:
	var xx = (x + width) % width
	var yy = (y + height) % height
	return xx + yy * width

# Re-initialize the U/V arrays with a classic Gray-Scott pattern
func _reset_fields() -> void:
	# Option to use a random pattern:
	_reset_fields_random()
	# Alternatively, use an image-based initialization:
	#_reset_fields_from_image("res://icon.png")

# Random initialization of U and V fields
func _reset_fields_random() -> void:
	# Fill U with random values between 0 and 1, and V with random values between 0 and 1
	for i in range(width * height):
		U[i] = randf()  # random U value
		V[i] = randf()  # random V value
	
	# Update the image for display using vibrant colors
	for y in range(height):
		for x in range(width):
			var idx = x + y * width
			var hue = (U[idx] - V[idx] + 1.0) / 2.0
			img.set_pixel(x, y, Color.from_hsv(hue, 1.0, 1.0, 1.0))
	texture.update(img)

# Image-based initialization of U and V fields
func _reset_fields_from_image(image_path: String) -> void:
	# Load an image from disk
	var pattern_img = Image.new()
	var err = pattern_img.load(image_path)
	if err != OK:
		push_error("Failed to load pattern image: " + str(err))
		return
	
	for y in range(height):
		for x in range(width):
			var idx = x + y * width
			var color = pattern_img.get_pixel(x, y)
			# Example: assign red channel to U, green channel to V
			U[idx] = color.r
			V[idx] = color.g
	
	# Update the display image using vibrant colors
	for y in range(height):
		for x in range(width):
			var idx = x + y * width
			var hue = (U[idx] - V[idx] + 1.0) / 2.0
			img.set_pixel(x, y, Color.from_hsv(hue, 1.0, 1.0, 1.0))
	texture.update(img)

# ==============================
# RESET FUNCTION (EVERY reset_interval SECONDS)
# ==============================
func _on_Reset_Timer() -> void:
	print("🔄 Resetting Reaction–Diffusion...")
	_reset_fields()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
