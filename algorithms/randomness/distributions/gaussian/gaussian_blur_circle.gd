# @identity
# essence: gaussian blur as time — sharp circle slowly dissolves into a soft mound
# desire: watch a hard edge surrender to the kernel, frame by frame
# critical_parameter: max_blur_radius — the asymptotic spread that determines how blurred "fully blurred" looks; sitter — WHO sits for the portrait, which decides which face of the gaussian the picture shows (disc | edge | dot | lattice | field)
# triggers: blur_time accumulates each frame; current_blur_radius interpolates and CPU re-blurs the image to the texture
# emerges: a 128x128 image that mirrors the gaussian PDF — a black disc relaxing into a fading bell
# needs: blur radius slider [missing]; reset button [missing]; pause toggle [missing]
# relationships: paired with GaussianBlurShader (GPU sibling, same idea, faster); cousin of GaussianPaintSplatter (gaussian as scatter, not smear)
# truth: Blur is integration in disguise. The pixel does not move — it averages with all its neighbors, weighted by distance, until certainty becomes a guess.

extends MeshInstance3D
class_name GaussianBlurCircle

# Constants
const DEFAULT_WIDTH := 128  # Was 640 — CPU blur is O(w*h*kernel), must be small
const DEFAULT_HEIGHT := 128
const CIRCLE_RADIUS := 40

# ─────────────────────────────────────────────────────────────────────────────
# DNA — sitter
#
# This artifact is a KERNEL, not a sample. It draws no random numbers at all:
# it takes something already drawn and averages every pixel with its neighbours
# under exp(-i²/2σ²). So the axis cannot be "how much randomness" — there is
# none here — and it cannot be the blur amount either, because a rate, a
# duration and a growing radius are all invisible to a still (the capture lands
# at ~1.1 s, radius ≈ 1.7 px, and five tiles of the same disc at five blur
# stages would be five pictures of the capture harness's clock).
#
# What this thing actually argues is settled by WHAT IS PUT UNDER THE KERNEL.
# Optics has known this for a century: you cannot photograph a lens, so you
# photograph a target and read the lens off what it did to it. Change the
# target and a different face of the same gaussian appears:
#
#   sitter   who sits for the portrait of the curve
#
#     disc     one object, hard-edged. The kernel reads as LOSS: a thing you
#              could name dissolving into a mound you cannot. THE LEGACY
#              LINEAGE, pixel for pixel — 18 rooms already have this one.
#     edge     one boundary, a half-plane. Blur a step and the profile that
#              comes back is the gaussian's INTEGRAL — the cumulative curve,
#              the S. The same law, photographed one derivative up.
#     dot      one sample, six pixels wide. What comes back is the kernel
#              ITSELF, the point spread function, the bell with nothing else
#              in the frame. The law photographed naked, and nearly invisible,
#              which is the honest size of one draw.
#     lattice  twenty-five separate objects on a pitch. Blur is INDIVIDUATION
#              LOST: the frame goes from twenty-five things to one grey
#              texture, and there is no radius at which you can say it stopped
#              being both.
#     field    no object at all — a seeded salt-and-pepper field. Here the
#              kernel is not destroying structure but MAKING it: white noise
#              blurs into blobs, correlation out of nothing, which is the
#              claim every smooth-looking natural thing rests on.
#
# THE LADDER RUNS law ← → instances: dot and field are made of samples, disc
# and edge are made of the shape, lattice sits between and refuses to choose.
# That is the same question the four artifacts of this tier disagree about, so
# this axis asks it in the one register a blur has: what it was pointed at.
#
# WHAT IS DELIBERATELY NOT THE AXIS. blur_duration, max_blur_radius and the
# ease curve are the tempting knobs and all three are TIME. R2 rules them out
# and so does the identity: "watch a hard edge surrender" is a claim about what
# surrender looks like, not how fast.
#
# NOT TOUCHED: the kernel. _generate_gaussian_kernel, the separable two-pass
# convolution, the 128×128 buffer and the ease schedule are identical at every
# value. This axis changes the sitter, never the lens.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — what is placed under the kernel. "disc" is the legacy default.
@export_enum("disc", "edge", "dot", "lattice", "field") var sitter: String = "disc"

## The allow-list, same five words in the same spelling as the @export_enum
## above. This is what a map token (#sitter:) is checked against.
const SITTERS: PackedStringArray = ["disc", "edge", "dot", "lattice", "field"]

## RNG. `field` is the ONLY value in this artifact that rolls anything, and it
## rolls from a LOCAL RandomNumberGenerator seeded here — never the global
## stream — so the same seed gives the same field every run and no other
## artifact's sequence moves because this one was built. Every other sitter,
## including the default, still draws exactly zero random numbers.
@export var field_seed: int = 20260802

const DOT_RADIUS := 6       # `dot` — one sample, kept solid enough to survive the blur
const LATTICE_COUNT := 5    # `lattice` — a 5×5 pitch of squares
const LATTICE_CELL := 12    # `lattice` — each square, in pixels
const FIELD_BLOCK := 4      # `field` — noise cell in pixels (1 px noise reads as flat grey)

# Image properties
var original_image := Image.new()
var current_image := Image.new()
var texture := ImageTexture.new()
var width := DEFAULT_WIDTH
var height := DEFAULT_HEIGHT

# Animation control
var blur_time := 0.0
var blur_duration := 10.0  # Duration to go from sharp to fully blurred
var max_blur_radius := 8.0  # Maximum blur kernel radius (keep small for CPU blur)
var current_blur_radius := 0.0
var active := true

func _ready() -> void:
	_initialize_image()
	_setup_material()

# Initialize the image with a sharp circle
func _initialize_image() -> void:
	original_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	current_image = Image.create(width, height, false, Image.FORMAT_RGBA8)

	if original_image.get_data().size() == 0:
		push_error("Failed to create image for Gaussian blur circle")
		return

	# Fill with white background
	original_image.fill(Color.WHITE)

	# THE SITTER, dispatched. `disc` is the legacy lineage: _sit_disc() carries
	# the hard-edge circle loop that used to stand inline here, line for line, so
	# the default writes the identical 128×128 buffer it always wrote.
	match sitter_name():
		"edge":
			_sit_edge()
		"dot":
			_sit_dot()
		"lattice":
			_sit_lattice()
		"field":
			_sit_field()
		_:
			_sit_disc()

	# Copy to current image
	current_image.copy_from(original_image)

	# Create texture
	texture = ImageTexture.create_from_image(current_image)
	print("GaussianBlurCircle: Initialized with sharp circle")

# Setup the material with the texture
func _setup_material() -> void:
	var new_material := StandardMaterial3D.new()
	new_material.albedo_texture = texture
	new_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material_override = new_material

var _frame_skip: int = 0

func _process(delta: float) -> void:
	if not active:
		return

	# Only update blur every 4th frame (CPU blur is expensive)
	_frame_skip += 1
	if _frame_skip < 4:
		return
	_frame_skip = 0

	if blur_time < blur_duration:
		blur_time += delta * 4.0  # Compensate for frame skip
		var progress = min(blur_time / blur_duration, 1.0)

		current_blur_radius = ease(progress, 0.5) * max_blur_radius

		_apply_gaussian_blur()
		texture.update(current_image)

# Apply Gaussian blur to the image
func _apply_gaussian_blur() -> void:
	if current_blur_radius < 0.5:
		# No blur needed yet, just copy original
		current_image.copy_from(original_image)
		return

	# Reset current image
	current_image.copy_from(original_image)

	# Create temporary image for blur result
	var temp_image := Image.create(width, height, false, Image.FORMAT_RGBA8)

	var kernel_size := int(ceil(current_blur_radius * 2))
	var sigma := current_blur_radius / 2.0

	# Generate Gaussian kernel
	var kernel := _generate_gaussian_kernel(kernel_size, sigma)

	# Apply horizontal blur
	for y in range(height):
		for x in range(width):
			var color_sum := Color(0, 0, 0, 0)
			var weight_sum := 0.0

			for i in range(-kernel_size, kernel_size + 1):
				var sample_x = clamp(x + i, 0, width - 1)
				var weight = kernel[i + kernel_size]
				color_sum += original_image.get_pixel(sample_x, y) * weight
				weight_sum += weight

			if weight_sum > 0:
				temp_image.set_pixel(x, y, color_sum / weight_sum)

	# Apply vertical blur
	for y in range(height):
		for x in range(width):
			var color_sum := Color(0, 0, 0, 0)
			var weight_sum := 0.0

			for i in range(-kernel_size, kernel_size + 1):
				var sample_y = clamp(y + i, 0, height - 1)
				var weight = kernel[i + kernel_size]
				color_sum += temp_image.get_pixel(x, sample_y) * weight
				weight_sum += weight

			if weight_sum > 0:
				current_image.set_pixel(x, y, color_sum / weight_sum)

# Generate 1D Gaussian kernel
func _generate_gaussian_kernel(radius: int, sigma: float) -> Array:
	var kernel := []
	var sum := 0.0

	for i in range(-radius, radius + 1):
		var value := exp(-(i * i) / (2.0 * sigma * sigma))
		kernel.append(value)
		sum += value

	# Normalize kernel
	for i in range(kernel.size()):
		kernel[i] /= sum

	return kernel

# Public API
func reset() -> void:
	"""Reset the animation"""
	blur_time = 0.0
	current_blur_radius = 0.0
	current_image.copy_from(original_image)
	texture.update(current_image)
	print("GaussianBlurCircle: Reset to sharp circle")

func pause() -> void:
	"""Pause the blur animation"""
	active = false

func resume() -> void:
	"""Resume the blur animation"""
	active = true

func set_blur_duration(duration: float) -> void:
	"""Set the duration of the blur animation"""
	blur_duration = duration

func set_max_blur_radius(radius: float) -> void:
	"""Set the maximum blur radius"""
	max_blur_radius = radius

func apply_grid_config(config: Dictionary) -> void:
	# Only the sitter is configurable from a map. A placement that does not name
	# one returns here having done nothing, which is why all 18 existing rooms
	# keep the disc they have always had.
	if not config.has("sitter"):
		return
	var want: String = str(config["sitter"]).strip_edges().to_lower()
	if not SITTERS.has(want):
		push_warning("gaussian_blur_circle: unknown sitter '%s' — keeping '%s'" % [want, sitter])
		return
	if want == sitter:
		return
	sitter = want
	# Re-sit and start the exposure again: a new sitter arrives sharp.
	blur_time = 0.0
	current_blur_radius = 0.0
	_initialize_image()
	_setup_material()


# ── THE SITTER ───────────────────────────────────────────────────────────────
# One function per value. Each fills `original_image` (already white) with black
# and nothing else — no material, no camera, no timing changes anywhere, so the
# lens is provably identical across the five and the only variable is the sitter.

## The reader. Lower, strip, and fall back to the legacy value on anything
## unrecognised: a typo must not blank a picture 18 rooms expect to be there.
func sitter_name() -> String:
	var v: String = sitter.strip_edges().to_lower()
	if SITTERS.has(v):
		return v
	if v != "":
		push_warning("gaussian_blur_circle: unknown sitter '%s' — keeping 'disc'" % v)
	return "disc"


## DISC — the legacy sitter, moved here unchanged. One hard-edged object,
## radius 40 of 128, centred: 30% of the buffer goes black.
func _sit_disc() -> void:
	var center_x := width / 2
	var center_y := height / 2

	for y in range(height):
		for x in range(width):
			var dx := x - center_x
			var dy := y - center_y
			var distance := sqrt(dx * dx + dy * dy)

			# Hard edge circle
			if distance <= CIRCLE_RADIUS:
				original_image.set_pixel(x, y, Color.BLACK)


## EDGE — a half-plane: the left half black, the right half white, one straight
## boundary down the middle. Blurring a step returns the gaussian's integral, so
## the seam that comes back is the cumulative curve rather than the bell.
func _sit_edge() -> void:
	var half: int = width / 2
	for y in range(height):
		for x in range(half):
			original_image.set_pixel(x, y, Color.BLACK)


## DOT — one sample. A six-pixel disc at the centre and nothing else, so what
## the blur returns is the point spread function: the kernel with no subject
## left to hide behind. Small on purpose; one draw IS small.
func _sit_dot() -> void:
	var center_x := width / 2
	var center_y := height / 2
	for y in range(center_y - DOT_RADIUS, center_y + DOT_RADIUS + 1):
		for x in range(center_x - DOT_RADIUS, center_x + DOT_RADIUS + 1):
			var dx := x - center_x
			var dy := y - center_y
			if dx * dx + dy * dy <= DOT_RADIUS * DOT_RADIUS:
				original_image.set_pixel(x, y, Color.BLACK)


## LATTICE — twenty-five squares on a regular pitch. The same ink as the disc,
## divided into things you can count. Blur is where the count stops being
## possible, and no frame in the run says which one it was.
func _sit_lattice() -> void:
	var pitch: int = width / (LATTICE_COUNT + 1)
	var half: int = LATTICE_CELL / 2
	for r in range(LATTICE_COUNT):
		for c in range(LATTICE_COUNT):
			var cx: int = pitch * (c + 1)
			var cy: int = pitch * (r + 1)
			for y in range(cy - half, cy + half):
				for x in range(cx - half, cx + half):
					if x >= 0 and x < width and y >= 0 and y < height:
						original_image.set_pixel(x, y, Color.BLACK)


## FIELD — no object: a 4×4-pixel salt-and-pepper field, black or white by coin
## flip. The one sitter made of random draws, and the one that shows the kernel
## MAKING structure instead of eating it — smooth blobs out of independent
## noise, which is what "natural-looking" always turns out to mean.
##
## Local generator, seeded from field_seed. Nothing here touches the global
## stream, so a scene that seeded itself elsewhere is unaffected, and the same
## seed renders the same field tomorrow.
func _sit_field() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = field_seed
	var y: int = 0
	while y < height:
		var x: int = 0
		while x < width:
			if rng.randf() < 0.5:
				for yy in range(y, mini(y + FIELD_BLOCK, height)):
					for xx in range(x, mini(x + FIELD_BLOCK, width)):
						original_image.set_pixel(xx, yy, Color.BLACK)
			x += FIELD_BLOCK
		y += FIELD_BLOCK
