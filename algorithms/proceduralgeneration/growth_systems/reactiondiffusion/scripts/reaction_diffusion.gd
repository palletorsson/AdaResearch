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
func _ready():
	if mesh_instance == null:
		push_error("MeshInstance3D not found!")
		return

	# 1) Resize the U and V arrays
	U.resize(width * height)
	V.resize(width * height)

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
func _on_Timer_timeout():
	# Create new arrays to hold the next state
	var U_next = PackedFloat32Array()
	U_next.resize(U.size())
	var V_next = PackedFloat32Array()
	V_next.resize(V.size())

	# For each cell, compute Laplacian and update
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
			U_next[idx] = clamp(u + du * interval, 0.0, 1.0)
			V_next[idx] = clamp(v + dv * interval, 0.0, 1.0)

	# Swap in the new data
	U = U_next
	V = V_next

	# Update the image with vibrant colors by mapping the difference between U and V to a hue
	for y in range(height):
		for x in range(width):
			var idx = x + y * width
			# Map the difference to a hue in the 0-1 range
			var hue = (U[idx] - V[idx] + 1.0) / 2.0
			# Use full saturation and brightness for vibrancy
			img.set_pixel(x, y, Color.from_hsv(hue, 1.0, 1.0, 1.0))
	texture.set_image(img)

# ==============================
# HELPER FUNCTIONS
# ==============================
# Simple material assignment
func _assign_texture_to_mesh(mesh_inst: MeshInstance3D, tex: Texture2D):
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
func _reset_fields():
	# Option to use a random pattern:
	_reset_fields_random()
	# Alternatively, use an image-based initialization:
	#_reset_fields_from_image("res://icon.png")

# Random initialization of U and V fields
func _reset_fields_random():
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
	texture.set_image(img)

# Image-based initialization of U and V fields
func _reset_fields_from_image(image_path: String):
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
	texture.set_image(img)

# ==============================
# RESET FUNCTION (EVERY reset_interval SECONDS)
# ==============================
func _on_Reset_Timer():
	print("🔄 Resetting Reaction–Diffusion...")
	_reset_fields()
