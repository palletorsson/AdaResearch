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

const PBR := preload("res://commons/render/pbr_kit.gd")
const MK := preload("res://commons/render/mesh_kit.gd")

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

# ─────────────────────────────────────────────────────────────────────────────
# THE SUPPORT — materials, and the tray the print lies in
#
# The render lint measured this artifact FLAT: tonal spread under 0.055 and
# fewer than 40 distinct colours across the subject. It was telling the truth,
# and for a reason that had nothing to do with the kernel. The picture was a
# 10 × 20 m PlaneMesh wearing a StandardMaterial3D with one albedo texture and
# nothing else — Godot's default roughness 1.0, no specular breakup, no
# support, and a background of Color.WHITE, which is albedo 1.0. Nothing in
# nature reflects 1.0. Under the capture rig's 1.2 key the paper simply clipped,
# and a clipped surface has no rolloff left to vary with.
#
# So the fix has two halves, and only the first one is about the picture.
#
# 1. THE PRINT. Everything here is SPECULAR. Not one change touches what the
#    sitter drew, because the subject of this artifact is an image operation and
#    a surface that competes with it is a surface that lies about the maths.
#      * albedo_color drops to a fibre-paper white (0.82) that the texture
#        multiplies into. The disc is still 0.0 and the ground is still the
#        brightest thing in frame — the RATIO the demonstration depends on is
#        untouched — but the sheet now has headroom above it, so a highlight can
#        exist at all.
#      * a roughness texture, so the gloss lobe breaks into mottle instead of
#        sweeping across twenty metres as one clean wash.
#      * a clear coat: a resin-coated print has a hard film over the emulsion,
#        and on a plane this large the half-vector swings enough from the near
#        edge to the far one that the coat alone draws a broad gradient. That
#        gradient IS the tonal spread the lint was asking for, and it costs the
#        demonstration nothing.
#
#    THE TRAP, and it would have destroyed the artifact: every PbrKit material
#    is TRIPLANAR by default, and Godot's triplanar path applies to uv1 — which
#    means albedo_texture too. Left on, the 128 × 128 picture would have been
#    projected in local space at PbrKit's tiling and tiled two by four times
#    across the sheet instead of stretched once over it. The picture, not the
#    finish. So the print material turns uv1_triplanar OFF and pins uv1_scale to
#    1: the plane's own UVs, the picture mapped once, and the grain textures
#    stretched once with it. See _setup_material for the grain arithmetic.
#
# 2. THE FURNITURE, which did not exist. This thing is a photograph — the
#    identity above has been saying so all along: a sitter, a portrait, an
#    exposure that starts again when a new sitter arrives. A print lies in a
#    developing tray. So it has one now: an enamelled steel tray, a rubber
#    gasket seam, a rolled base plate, two lip bars and four brass weights
#    holding the corners flat while it soaks.
#
#    The tray is IDENTICAL AT ALL FIVE SITTERS — it is furniture, not axis — and
#    every part of it sits BELOW the print plane except the weights and the
#    bars, which stand on the margin outside it. No sitter's picture is cropped,
#    occluded or recoloured, and `disc` still writes the same buffer it always
#    wrote. What the tray adds is what a plane cannot have: an edge, a step, a
#    curved metal surface where a highlight can roll, and four materials that
#    are not the same colour as each other.
# ─────────────────────────────────────────────────────────────────────────────

## Fibre-based paper, not paper as a light source. 0.82 is about what a bright
## photographic base actually reflects; 1.0 was the clip.
const PAPER := Color(0.820, 0.812, 0.796)

## Vitreous-enamelled steel, the colour a darkroom tray usually is. Deliberately
## a MID tone and deliberately COOL: it has to separate from the warm paper
## without going near the black that three agreeing darkenings produce.
const TRAY_ENAMEL := Color(0.300, 0.335, 0.352)

const TRAY_MARGIN := 0.34   # enamel showing outside the print, metres
const TRAY_H := 0.070       # the tray shell
const GASKET_H := 0.016     # the dark seam between shell and base plate
const BASE_H := 0.050       # the rolled base plate, proud of the shell
const WEIGHT_R := 0.34      # a corner weight
const WEIGHT_H := 0.090
const BAR_R := 0.065        # the lip bars across the short ends

# ── GRAIN SCALE ──────────────────────────────────────────────────────────────
# Lesson bought elsewhere in this pass and imported whole: a grain sized for a
# 30 mm bolt head, put on a 20 m body, is not detail. It is one texture feature
# per pixel, which is television static.
#
# This artifact is 10 m across X and 20 m along Z. The published render fits its
# bounding SPHERE (diagonal 22.4 m) into a 760 px frame, so the whole object is
# photographed at roughly 34 px per metre. A feature has to be about 0.15 m
# before it is 5 px wide and can be seen as texture rather than as noise.
#
# PbrKit's GRAIN_MICRO puts its base octave at about 4% of one tile, so:
#
#     feature ≈ 0.04 / uv1_scale        (uv1_scale is tiles per metre)
#
# and a 0.24 m feature — 8 px — wants uv1_scale ≈ 0.167, one tile per six
# metres. That is the number below, expressed as a multiplier on whatever the
# kit builder set, because scale_detail() multiplies rather than assigns.
#
# NOTE that the kit's rule of thumb (factor ≈ 1 / longest_dimension) is a
# STARTING POINT and it is wrong for the small parts here. It assumes a viewer
# at arm's length. Every part of this artifact is seen at the SAME 34 px per
# metre, so a 0.68 m brass weight wants nearly the same WORLD tile size as the
# 20 m tray — not the 1/0.68 the rule would give, which would land its grain at
# a fifth of a pixel.
const DETAIL_TRAY := 0.0556   # painted_metal 3.0 → 0.167 t/m → 0.24 m ≈ 8 px
const DETAIL_BASE := 0.0556   # brushed_metal 3.0 → 0.167 t/m (top face)
const DETAIL_GASKET := 0.037  # rubber 9.0 → 0.333 t/m → 0.12 m ≈ 4 px
const DETAIL_WEIGHT := 0.0667 # machined_metal 6.0 → 0.4 t/m → 0.10 m ≈ 3 px
const DETAIL_PLATE := 0.222   # painted_metal 3.0 → 0.667 t/m, a 0.2 m strip

## The print's gloss. Below ~0.35 the coat has no lobe left and the sheet goes
## back to matte nothing; above ~0.6 it starts to mirror and the picture reads
## through a window instead of off a surface.
const PRINT_GLOSS := 0.42

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
	_build_support()

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
#
# The print. See THE SUPPORT above for why every change here is specular and
# none of it is albedo — the sitter draws the picture, this only decides what
# kind of surface the picture is printed ON.
func _setup_material() -> void:
	# hard_plastic is the right builder for a resin-coated print: a dielectric
	# with a clear film over it. It arrives carrying a roughness texture, a fine
	# normal and a clearcoat lobe, which is the whole distance from the Godot
	# default this material used to be.
	var m: StandardMaterial3D = PBR.hard_plastic(PAPER, PRINT_GLOSS, 0.03)
	m.albedo_texture = texture

	# TRIPLANAR OFF. This is the one line that matters. PbrKit builds every
	# material triplanar, and Godot's triplanar path covers uv1 — albedo
	# included — so leaving it on would project the 128 × 128 picture in local
	# space at 5 tiles per metre and repeat it fifty times down the sheet. With
	# it off and uv1_scale pinned to 1, the PlaneMesh's own 0..1 UVs map the
	# picture exactly once, the way they always have.
	m.uv1_triplanar = false
	m.uv1_scale = Vector3.ONE
	m.uv1_offset = Vector3.ZERO

	# WHICH SETS THE GRAIN SCALE BY HAND, and lands it in the right band by
	# accident of geometry: one 256 px tile stretched once across 10 × 20 m puts
	# GRAIN_MICRO's base octave at ~0.4 m by ~0.8 m — 14 to 27 px in the
	# published frame — with its finer octaves running down to ~2 px. Coarse
	# mottle over fine tooth. That is what fibre paper does, and it is four
	# hundred times larger than the same grain would have been at the kit's
	# default tiling, which is the failure this whole pass is about.

	# Fresnel. On a plane this wide the view angle swings hard from the near
	# edge to the far one, so the rim term reads as a gradient rather than as a
	# glow — but it is also the fastest way back to a clipped edge, so it goes
	# in at half the kit's default and tinted toward the paper rather than white.
	m.rim = 0.14
	m.rim_tint = 0.55
	material_override = m

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


# ── THE TRAY ─────────────────────────────────────────────────────────────────
# Furniture, built once, identical at every sitter. Nothing here reads `sitter`
# and nothing here touches original_image, so the axis is provably untouched:
# swap the sitter and the same tray holds a different picture.


## The print's real extents, read from the mesh rather than assumed, so the tray
## still fits if the PlaneMesh in the .tscn is ever resized.
func _plate_size() -> Vector2:
	var pm: PlaneMesh = mesh as PlaneMesh
	if pm != null:
		return Vector2(maxf(pm.size.x, 0.5), maxf(pm.size.y, 0.5))
	var ab: AABB = get_aabb()
	return Vector2(maxf(ab.size.x, 0.5), maxf(ab.size.z, 0.5))


func _build_support() -> void:
	if has_node("Support"):
		return
	var holder := Node3D.new()
	holder.name = "Support"
	add_child(holder)

	var s: Vector2 = _plate_size()
	var hw: float = s.x * 0.5
	var hd: float = s.y * 0.5

	# The stack, downward from the print at y = 0. Every offset is negative:
	# the total depth below the sheet is 0.139 m, which is also exactly how far
	# the grid's auto-ground will now lift this artifact. That is deliberate and
	# it is small — see the note at the bottom of this function.
	var tray_top: float = -0.003
	var tray_y: float = tray_top - TRAY_H * 0.5
	var gasket_y: float = tray_top - TRAY_H - GASKET_H * 0.5
	var base_y: float = tray_top - TRAY_H - GASKET_H - BASE_H * 0.5

	# ── the enamelled shell ──────────────────────────────────────────────
	# painted_metal is honest here: enamel IS a dielectric film fired onto
	# steel, and at wear 0.26 the builder stays below its own weathering
	# threshold, so the only darkenings on this surface are the paint's own
	# and the box's baked underside. Two. Never three.
	var enamel: StandardMaterial3D = PBR.painted_metal(TRAY_ENAMEL, 0.26, 0.28, 0.48)
	PBR.scale_detail(enamel, DETAIL_TRAY)
	var shell: MeshInstance3D = PBR.box(
		Vector3(0.0, tray_y, 0.0),
		Vector3(s.x + TRAY_MARGIN * 2.0, TRAY_H, s.y + TRAY_MARGIN * 2.0),
		enamel, 0.020, 0.22)
	shell.name = "TrayShell"
	holder.add_child(shell)

	# ── the gasket seam ──────────────────────────────────────────────────
	# A 16 mm rubber line, proud of the shell and inset from the base plate, so
	# the two bright plates are separated by something dark. It costs 44
	# triangles and it is the strongest piece of local contrast on the object.
	var seal: StandardMaterial3D = PBR.rubber(PBR.RUBBER_BLACK, 0.30)
	PBR.scale_detail(seal, DETAIL_GASKET)
	var gasket: MeshInstance3D = PBR.box(
		Vector3(0.0, gasket_y, 0.0),
		Vector3(s.x + TRAY_MARGIN * 2.48, GASKET_H, s.y + TRAY_MARGIN * 2.48),
		seal, 0.005, 0.0)
	gasket.name = "GasketSeam"
	holder.add_child(gasket)

	# ── the base plate ───────────────────────────────────────────────────
	# Rolled steel, brushed. Axis "y" on purpose: the kit's stretch then lands
	# on the two horizontal components equally, so the plate's TOP face — the
	# only face this artifact is ever seen from — gets isotropic grain rather
	# than a brush direction that would be arbitrary on a floor-lying object.
	var plate_steel: StandardMaterial3D = PBR.brushed_metal(PBR.STEEL, 0.32, 0.28, "y")
	PBR.scale_detail(plate_steel, DETAIL_BASE)
	var base: MeshInstance3D = PBR.box(
		Vector3(0.0, base_y, 0.0),
		Vector3(s.x + TRAY_MARGIN * 2.94, BASE_H, s.y + TRAY_MARGIN * 2.94),
		plate_steel, 0.016, 0.30)
	base.name = "BasePlate"
	holder.add_child(base)

	# ── four corner weights ──────────────────────────────────────────────
	# The one CURVED surface on the whole artifact, and the reason they are
	# worth 500 triangles: a flat plane under a directional key has a constant
	# diffuse term and can only vary through its specular. A turned brass disc
	# rolls a highlight from bright to dark across its own width, which is a
	# tonal range no amount of texture on a plane will produce.
	#
	# MeshKit rather than PbrKit here: cone()'s cap fillet is tangent-continuous
	# with the barrel, so the rim catches a bright line with no shading crease.
	var brass: StandardMaterial3D = PBR.machined_metal(PBR.BRASS, 0.20, 0.14)
	PBR.scale_detail(brass, DETAIL_WEIGHT)
	var weight_mesh: ArrayMesh = MK.cylinder(WEIGHT_R, WEIGHT_H, 14, 0.018, 1, true)
	var inset: float = WEIGHT_R + 0.11
	for i in range(4):
		var sx: float = -1.0 if i < 2 else 1.0
		var sz: float = -1.0 if (i % 2) == 0 else 1.0
		var w: MeshInstance3D = MK.make_instance(weight_mesh, brass, "PrintWeight%d" % i)
		w.position = Vector3(sx * (hw - inset), WEIGHT_H * 0.5, sz * (hd - inset))
		holder.add_child(w)

	# ── two lip bars ─────────────────────────────────────────────────────
	# A tray has a lip you pour from. Visually they are two long cylinders lying
	# across the short ends: at 34 px per metre each is a 4 px bright streak
	# running the full width of the frame, which is a lot of highlight for 96
	# triangles.
	var bar_steel: StandardMaterial3D = PBR.brushed_metal(PBR.STEEL, 0.26, 0.20, "y")
	PBR.scale_detail(bar_steel, DETAIL_BASE)
	var bar_y: float = tray_top + BAR_R
	var bar_x: float = hw + TRAY_MARGIN * 0.88
	for i in range(2):
		var sz2: float = -1.0 + 2.0 * float(i)
		var zpos: float = sz2 * (hd + TRAY_MARGIN * 0.56)
		var bar: MeshInstance3D = PBR.pipe(
			Vector3(-bar_x, bar_y, zpos), Vector3(bar_x, bar_y, zpos),
			BAR_R, bar_steel, 12)
		bar.name = "LipBar%d" % i
		holder.add_child(bar)

	# ── the amber strip ──────────────────────────────────────────────────
	# One saturated colour, laid into the enamel margin. It is PAINT, not
	# emission: this corpus is already full of self-lit things and bloom was
	# switched off in the capture rig because it was fattening every bright line
	# past its own silhouette. A safelight-amber strip that merely reflects adds
	# the same hue to the palette and costs the exposure nothing.
	var amber: StandardMaterial3D = PBR.painted_metal(PBR.BRAUN_ACCENT, 0.12, 0.20, 0.44)
	PBR.scale_detail(amber, DETAIL_PLATE)
	var strip: MeshInstance3D = PBR.box(
		Vector3(hw + TRAY_MARGIN * 0.50, tray_top + 0.009, -hd * 0.55),
		Vector3(0.20, 0.018, 1.60), amber, 0.004, 0.0)
	strip.name = "SafelightStrip"
	holder.add_child(strip)

	# WHAT THIS DOES TO PLACED ROOMS, stated rather than discovered later.
	# Twenty maps place this artifact: eleven at y_offset 0.0 and seven at -0.5.
	# The AABB used to be 10 × 0 × 20 — zero height — so auto-ground returned
	# early and the sheet sat exactly coplanar with the floor, z-fighting it.
	# The tray gives the AABB a floor at -0.139, so auto-ground now lifts the
	# whole assembly by that much: the print ends up 139 mm above the floor
	# instead of inside it, which resolves the z-fight, and the buried
	# placements stay buried. Nothing rises higher than 128 mm, so no room gains
	# an obstacle.


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
