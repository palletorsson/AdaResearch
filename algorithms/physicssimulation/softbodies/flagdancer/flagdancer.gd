@tool
# PrideFlagVariations.gd - Utökad version med flera flaggor
extends Node3D

# @identity
# essence: Skeleton3D with per-bone sine wave displacement — each flag_bone gets xform.origin.z = base_wave + wind_noise, creating cloth-like ripple across a SurfaceTool-built pride flag mesh
# desire: to wave a pride flag in VR that responds to wind_strength and celebration_intensity — a flag you can make dance harder by pressing SPACE
# critical_parameter: wind_strength — controls the amplitude of the sine wave displacement; below 0.5 the flag barely stirs, above 1.5 it whips violently
# triggers: celebration_mode toggle (ui_accept) multiplies wave amplitude by 1.5 and adds bone rotation and scale stretching; flag_type enum switches the color stripe palette
# emerges: bone phase offsets create a travelling wave across the flag surface that looks like real wind even though it is just sin() with different offsets per bone
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]
# relationships: extends cloth_straps from static draping to animated wind; bridges soft body physics to affect theory in SoftBodies_Affect_Theory_Visualization
# truth: a flag is not a symbol displayed — it is a material surface negotiating wind, and the pride it carries lives in the physics of its motion

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION — flagdancer, 2026-08-12. TWO AXES.
#
#   crimp     THE SPATIAL PERIOD OF THE WAVE STANDING IN THE CLOTH
#             flat · swell · ripple · corrugation          (default: swell)
#   heading   WHICH EDGE THE CLOTH IS HELD BY
#             none · hoist · fly · both                    (default: none)
#
# THE PROBLEM THIS SEQUENCE SETS. Everything in softbodies moves, and the evidence
# for a DNA axis is ONE STILL. An axis over how fast the flag flaps is invisible to
# a photograph and would measure the shutter. So both axes here are chosen for the
# only property of a wave that survives being frozen: its SHAPE ALONG THE CLOTH.
#
# crimp — WHAT WAS HARD-CODED. `var wave_offset := i * 0.25`: a per-bone phase
# gradient. That 0.25 is a SPATIAL period, not a temporal one — over 17 bones it
# accumulates 4.25 rad, two thirds of one wave across six metres of flag — and a
# spatial period is exactly the thing a still can hold. `crimp` is the textile word
# for the wave standing in a fabric. flat 0.0 (every bone in phase), swell 0.25 (the
# shipped literal), ripple 0.6 (a wave and a half, two crests), corrugation 1.2
# (three waves, a fluted surface). The sine's frequency in t stays 2.0 in all four:
# this is emphatically NOT wind speed. What changes between the values is how many
# crests are in the picture, not how quickly they travel through it.
#
# heading — A FLAG IN THIS FILE IS HELD NOWHERE. Every bone got the same amplitude
# (0.4 and 0.15); `progress` entered the noise's PHASE and never its ENVELOPE. The
# shipped object is therefore a striped sheet floating free in space, while the
# @identity's own truth line says a flag is "a material surface negotiating wind" —
# and a surface negotiates with whatever holds it. `heading` is the vexillological
# and curtain-making name for the reinforced edge a cloth is attached by:
#   none    uniform 1.0 — the shipped lineage, applied by SKIPPING the multiply
#           entirely, so the origin.z expression is character for character the one
#           that shipped. No edge is privileged: a flag with no pole.
#   hoist   ramp 0 at bone 0 to 1 at bone 16. The mast edge is dead still, the fly
#           end swings its full travel — the classic tapering flag.
#   fly     the mirror. A cloth held at its free end, which is what a flag looks
#           like when someone is carrying it wrong, and it is legible precisely
#           because it is wrong.
#   both    sin(PI * edge) — zero at both ends, one belly in the middle. Bunting on
#           a line; a washing line, not a flag.
# NOT `suspension` (cloth_straps, spring_system): that axis names the FURNITURE a
# hanging body hangs from and builds a rank of steel around an untouched cloth. This
# one builds nothing, moves no prop, and changes which part of the cloth is allowed
# to move. Not `anchorage` (ant_colony_v2), not `hang` (gallery_winner_showcase),
# not `attach` (point).
#
# DECLINED, BY NAME. wind_strength is the @identity's declared critical_parameter
# and the most tempting knob in the file — and at a frozen phase it is nothing but a
# uniform amplitude multiplier on a sine, so four values are four SCALINGS of one
# shape, which the union-AABB camera then partly divides back out again. In motion
# it reads as speed-of-flapping, not as form. celebration_intensity is worse: it is
# only consulted while `celebration_mode` is true, and celebration_mode can only be
# turned on by a live ui_accept press that no capture will ever make, so all four
# values would render byte-identically. Also declined: the frequencies 2.0, 3.7 and
# 0.8 — pure rates, one photograph each of an arbitrary instant.
#
# DETERMINISM IS THE DELIVERABLE, AND AS SHIPPED THERE WAS NONE, TWICE OVER.
#   (1) The pose is a closed-form function of `t = Time.get_ticks_msec() * 0.001 +
#       time_offset`. There is no simulation to settle: the flag is never at rest,
#       so the shutter catches the wall clock and "has it settled by 1.45 s" is not
#       even the right question to ask of it.
#   (2) `time_offset = randf() * TAU` is drawn off the global generator with no seed.
#       Five variants of an unseeded generator are five different objects.
# The file LOOKS like it seeds something — `var noise_seed := int(time_offset*1000)
# % 1000` — and that local is never read again. It is decoration, not a seed. The
# second random draw, `randf_range(0.8, 1.2)`, lives in create_flag_parade(), which
# nothing in the repository calls; the live path has exactly ONE draw and it enters
# the pose through exactly one line.
# Two bench exports fix both, and BOTH DEFAULT TO "AS SHIPPED":
#   frozen_phase  -1.0 = read the clock (shipped). >= 0.0 = use that value as t and
#                 never read time_offset at all, which makes the pose a pure function
#                 of the exports — identical on every run and on every machine, and
#                 motionless, so there is no transient to photograph.
#   wave_seed     -1 = `randf() * TAU`, the shipped line and the same global-RNG
#                 draw. >= 0 = a local RandomNumberGenerator with seed = wave_seed.
#                 (`rng.seed = randi()` would be the OPPOSITE of seeding; the seed
#                 here is an explicit integer.) This one is for the world, not the
#                 bench: in a live map the phase must keep running, and this makes
#                 the flag the same flag on every launch.
#
# THE DEFAULT IS A SHORT-CIRCUIT, NOT A NEAR MISS. crimp=swell returns the literal
# 0.25 that line 191 already multiplied by i; heading=none returns before the
# envelope multiply is reached, so `xform.origin.z = base_wave + wind_noise` is
# computed from exactly the shipped expressions. THIRTEEN appearances are untouched:
# 5 grid tokens (SoftBodies_Obsticals as `flagdancer:90`, SoftBodies_Obsticals_p1 /
# _p2 / _p3 and Corridor_SoftBodies_Obsticals as the bare token — a rotation suffix
# is not a config, so merged_config is empty and apply_grid_config is never called at
# all), 7 `exhibit_furniture#kind:floor_work#size:l#mount:flagdancer` slots
# (Trial_castelvecchio / grande / kanazawa / lattice_pm_17 / sainsbury / uffizi /
# wfc_softbodies) which instantiate the scene and forward nothing of their own, and
# the Curation_Bay_softbodies_0 roster.
#
# THIS FILE IS @tool: _ready() runs in the editor, so every export added here must be
# safe to evaluate with no scene tree. All four are pure value reads.
# ─────────────────────────────────────────────────────────────────────────────

enum FlagType {
	RAINBOW,
	TRANS,
	BISEXUAL,
	NONBINARY,
	PANSEXUAL,
	LESBIAN,
	ASEXUAL
}

@export var flag_type: FlagType = FlagType.RAINBOW
@export var wind_strength: float = 1.0
@export var celebration_intensity: float = 1.0

## AXIS — the spatial period of the wave standing in the cloth. `swell` is the
## shipped lineage: it returns the literal 0.25 that `i * 0.25` already used.
@export_enum("flat", "swell", "ripple", "corrugation") var crimp: String = "swell"

## AXIS — which edge the cloth is held by, as an amplitude envelope along the bones.
## `none` is the shipped lineage and is applied by skipping the multiply entirely.
@export_enum("none", "hoist", "fly", "both") var heading: String = "none"

## BENCH — pin the pose. Below 0.0 the clock is read exactly as it always was.
## At or above 0.0 this value IS t, so the flag is motionless and the picture is a
## pure function of the exports. See the promotion note: there is no simulation here
## to settle, so a still of the running artifact is a still of the wall clock.
@export var frozen_phase: float = -1.0

## WORLD — repeatability where the phase must keep running. Below 0 leaves
## `time_offset = randf() * TAU`, the shipped draw off the global generator. At or
## above 0 a local RandomNumberGenerator is seeded with this exact integer.
@export var wave_seed: int = -1

## The allow-lists a map token is checked against. An unknown word keeps the shipped
## behaviour rather than stranding a placement in a shape nobody declared.
const CRIMPS: PackedStringArray = ["flat", "swell", "ripple", "corrugation"]
const HEADINGS: PackedStringArray = ["none", "hoist", "fly", "both"]

@onready var skeleton: Skeleton3D
@onready var skinned_mesh:  MeshInstance3D
var flag_bones: Array[int] = []
var time_offset: float = 0.0
var celebration_mode: bool = false

## Every node THIS SCRIPT created, so _exit_tree frees its own work and only its own.
var _owned: Array[Node] = []

## Signature of every value the pose reads, primed in _ready() with the shipped ones.
var _config_sig: String = ""

# Flaggfärger för olika Pride-flaggor
var flag_colors: Dictionary = {
	FlagType.RAINBOW: [
		Color(0.91, 0.11, 0.14),    # Red
		Color(1.0, 0.5, 0.0),       # Orange  
		Color(1.0, 0.93, 0.0),      # Yellow
		Color(0.0, 0.51, 0.18),     # Green
		Color(0.0, 0.32, 0.73),     # Blue
		Color(0.46, 0.11, 0.53)     # Purple
	] as Array[Color],
	FlagType.TRANS: [
		Color(0.35, 0.8, 0.98),     # Light blue
		Color(0.96, 0.67, 0.81),    # Pink
		Color(1.0, 1.0, 1.0),       # White
		Color(0.96, 0.67, 0.81),    # Pink
		Color(0.35, 0.8, 0.98)      # Light blue
	] as Array[Color],
	FlagType.BISEXUAL: [
		Color(0.84, 0.2, 0.64),     # Magenta
		Color(0.84, 0.2, 0.64),     # Magenta (thicker)
		Color(0.61, 0.35, 0.71),    # Purple
		Color(0.0, 0.32, 0.73),     # Blue
		Color(0.0, 0.32, 0.73)      # Blue (thicker)
	] as Array[Color],
	FlagType.NONBINARY: [
		Color(0.99, 0.96, 0.0),     # Yellow
		Color(1.0, 1.0, 1.0),       # White
		Color(0.61, 0.35, 0.71),    # Purple
		Color(0.0, 0.0, 0.0)        # Black
	] as Array[Color],
	FlagType.PANSEXUAL: [
		Color(1.0, 0.13, 0.58),     # Pink
		Color(1.0, 0.85, 0.0),      # Yellow
		Color(0.13, 0.7, 1.0)       # Blue
	] as Array[Color],
	FlagType.LESBIAN: [
		Color(0.84, 0.33, 0.0),     # Orange
		Color(1.0, 0.58, 0.25),     # Light orange
		Color(1.0, 1.0, 1.0),       # White
		Color(0.85, 0.51, 0.74),    # Light pink
		Color(0.64, 0.0, 0.32)      # Dark pink
	] as Array[Color],
	FlagType.ASEXUAL: [
		Color(0.0, 0.0, 0.0),       # Black
		Color(0.64, 0.64, 0.64),    # Gray
		Color(1.0, 1.0, 1.0),       # White
		Color(0.5, 0.0, 0.5)        # Purple
	] as Array[Color]
}

func _ready() -> void:
	create_pride_flag_with_bones()
	setup_joyful_animation()
	_config_sig = _sig(crimp, heading, frozen_phase, wave_seed)
	var flag_name = FlagType.keys()[flag_type]
	print("🏳️‍🌈 %s Pride flag ready! Press SPACE for celebration! 🏳️‍🌈" % flag_name)

func create_pride_flag_with_bones() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "FlagSkeleton"
	add_child(skeleton)
	_owned.append(skeleton)

	skinned_mesh =  MeshInstance3D.new()
	skinned_mesh.name = "FlagMesh"
	add_child(skinned_mesh)
	_owned.append(skinned_mesh)
	skinned_mesh.skeleton = skeleton.get_path()

	var colors: Array[Color] = flag_colors[flag_type]
	var flag_width := 6.0
	var flag_height := 4.0
	var segments_x := 16        # Ännu mjukare för vindeffekt
	var segments_y: int = colors.size()

	# Skapa ben för vindeffekt
	flag_bones.clear()
	for i in range(segments_x + 1):
		var bone_name := "flag_bone_%d" % i
		var bone_idx := skeleton.get_bone_count()
		skeleton.add_bone(bone_name)
		flag_bones.append(bone_idx)
		var x_pos := lerpf(-flag_width * 0.5, flag_width * 0.5, float(i) / float(segments_x))
		skeleton.set_bone_rest(bone_idx, Transform3D(Basis(), Vector3(x_pos, 0, 0)))

	# Bygg geometri med mjukare viktning mellan ben
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var verts_per_row := segments_x + 1
	for y in range(segments_y + 1):
		for x in range(segments_x + 1):
			var px := lerpf(-flag_width * 0.5, flag_width * 0.5, float(x) / float(segments_x))
			var py := lerpf(-flag_height * 0.5, flag_height * 0.5, float(y) / float(segments_y))
			var pos := Vector3(px, py, 0.0)

			# Färginterpolation mellan stripes
			var color_pos: float = float(y) / float(segments_y) * (colors.size() - 1)
			var color_idx := int(color_pos)
			var color_blend: float = color_pos - color_idx
			var vertex_color: Color
			
			if color_idx >= colors.size() - 1:
				vertex_color = colors[-1]
			else:
				vertex_color = colors[color_idx].lerp(colors[color_idx + 1], color_blend)

			st.set_color(vertex_color)
			st.set_normal(Vector3(0, 0, 1))
			st.set_uv(Vector2(float(x) / segments_x, float(y) / segments_y))

			# Mjukare bone weighting för naturligare deformation
			var bone_pos := float(x) / float(segments_x) * (flag_bones.size() - 1)
			var bone1 := int(bone_pos)
			var bone2 := mini(bone1 + 1, flag_bones.size() - 1)
			var blend := bone_pos - bone1
			
			var bone_indices := PackedInt32Array([bone1, bone2, 0, 0])
			var bone_weights := PackedFloat32Array([1.0 - blend, blend, 0.0, 0.0])
			
			st.set_bones(bone_indices)
			st.set_weights(bone_weights)
			st.add_vertex(pos)

	# Triangulering
	for y in range(segments_y):
		for x in range(segments_x):
			var i := y * verts_per_row + x
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(i + verts_per_row)
			st.add_index(i + 1)
			st.add_index(i + verts_per_row + 1)
			st.add_index(i + verts_per_row)

	skinned_mesh.mesh = st.commit()

func setup_joyful_animation() -> void:
	# SHIPPED PATH, character for character, whenever no seed is asked for — the same
	# draw off the same global generator, so the default consumes the RNG exactly as
	# it always did.
	if wave_seed < 0:
		time_offset = randf() * TAU
		return
	# SEEDED PATH. An explicit integer, not randi(): `rng.seed = randi()` is the
	# opposite of seeding and is the line that has fooled an audit in this codebase
	# before.
	var rng := RandomNumberGenerator.new()
	rng.seed = wave_seed
	time_offset = rng.randf() * TAU

## The phase gradient per bone. `swell` short-circuits to the shipped literal 0.25,
## so the default multiplies i by the same number the file always multiplied it by.
func _crimp_gradient() -> float:
	match crimp:
		"flat":
			return 0.0
		"swell":
			return 0.25
		"ripple":
			return 0.6
		"corrugation":
			return 1.2
	return 0.25

## The amplitude envelope along the cloth, `edge` running 0.0 at bone 0 to 1.0 at the
## last bone. Never called at heading=none — see the guard in _process.
func _heading_envelope(edge: float) -> float:
	match heading:
		"hoist":
			return edge
		"fly":
			return 1.0 - edge
		"both":
			return sin(PI * edge)
	return 1.0

func _sig(c: String, h: String, p: float, s: int) -> String:
	return "%s|%s|%.6f|%d" % [c, h, p, s]

func _process(_delta: float) -> void:
	if skeleton == null or flag_bones.is_empty():
		return

	# frozen_phase < 0.0 is the shipped expression, untouched. At or above 0.0 the
	# clock and time_offset are both left unread, which is what makes a capture of
	# this artifact a measurement rather than a photograph of the wall clock.
	var t: float = frozen_phase
	if frozen_phase < 0.0:
		t = float(Time.get_ticks_msec()) * 0.001 + time_offset

	var gradient: float = _crimp_gradient()
	var shaped: bool = heading != "none"
	var last_bone: float = float(maxi(flag_bones.size() - 1, 1))

	if Input.is_action_just_pressed("ui_accept"):
		celebration_mode = !celebration_mode
		var flag_name = FlagType.keys()[flag_type]
		print("🎉 %s flag celebration: %s! 🎉" % [flag_name, "ON" if celebration_mode else "OFF"])

	# Vindeffekt med noise för mer naturlig rörelse
	var noise_seed := int(time_offset * 1000) % 1000
	
	for i in range(flag_bones.size()):
		var bone_idx := flag_bones[i]
		var rest := skeleton.get_bone_rest(bone_idx)
		
		# Grundvåg + noise för mer naturlig vind
		# AXIS crimp: the gradient was the literal 0.25 and is now read from the
		# value. At swell the arithmetic below is identical to what shipped.
		var wave_offset: float = float(i) * gradient
		var progress := float(i) / float(flag_bones.size())
		
		# Grundvågor
		var base_wave := sin(t * 2.0 + wave_offset) * 0.4 * wind_strength
		var wind_noise := sin(t * 3.7 + progress * 8.0) * 0.15 * wind_strength
		
		var stretch_x := 1.0
		var stretch_y := 1.0
		
		if celebration_mode:
			var celebration_factor := celebration_intensity
			stretch_x = 1.0 + sin(t * 5.0 + wave_offset) * 0.4 * celebration_factor
			stretch_y = 1.0 + cos(t * 4.0 + wave_offset) * 0.25 * celebration_factor
			base_wave *= 1.5 * celebration_factor
			wind_noise *= 2.0 * celebration_factor
		else:
			stretch_x = 1.0 + sin(t * 2.0 + wave_offset) * 0.15
			stretch_y = 1.0 + cos(t * 1.5 + wave_offset) * 0.08

		var xform := rest
		xform.origin.z = base_wave + wind_noise
		# AXIS heading: at `none` this multiply is never reached, so the line above
		# is the whole story exactly as it was.
		if shaped:
			xform.origin.z *= _heading_envelope(float(i) / last_bone)
		# Lägg till lite rotation för mer dramatisk effekt
		if celebration_mode:
			xform.basis = xform.basis.rotated(Vector3.FORWARD, sin(t * 3.0 + wave_offset) * 0.1)
		xform.basis = xform.basis.scaled(Vector3(stretch_x, stretch_y, 1.0))

		skeleton.set_bone_pose(bone_idx, xform)

	# Global rotation för känsla av vind
	var wind_sway := sin(t * 0.8) * 0.03 * wind_strength
	if celebration_mode:
		wind_sway += sin(t * 2.0) * 0.05 * celebration_intensity
	rotation.z = wind_sway

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		create_themed_particles()

func create_themed_particles() -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 80
	particles.lifetime = 2.5
	particles.emission_sphere_radius = 2.5
	particles.gravity = Vector3(0, -1.5, 0)
	particles.initial_velocity_min = 4.0
	particles.initial_velocity_max = 10.0
	
	# Använd flaggans färger för partiklar
	var colors: Array[Color] = flag_colors[flag_type]
	var ramp := Gradient.new()
	for i in range(colors.size()):
		var point := float(i) / float(colors.size() - 1)
		ramp.add_point(point, colors[i])
	particles.color_ramp = ramp

	add_child(particles)
	_owned.append(particles)
	particles.emitting = true
	await get_tree().create_timer(3.5).timeout
	_owned.erase(particles)
	particles.queue_free()

# Scene setup helper (run from script or use as autoload)
func create_flag_parade() -> void:
	var flag_types = [FlagType.RAINBOW, FlagType.TRANS, FlagType.BISEXUAL, FlagType.NONBINARY]
	for i in range(flag_types.size()):
		var flag_scene = preload("res://algorithms/physicssimulation/softbodies/flagdancer/flagdancer.gd").new()
		flag_scene.flag_type = flag_types[i]
		flag_scene.position.x = i * 8.0 - 12.0
		flag_scene.wind_strength = randf_range(0.8, 1.2)
		add_child(flag_scene)

## Free ONLY what this script created. The previous version freed EVERY child with no
## owner, which is every node any other system had attached to this artifact at
## runtime — the skeleton and mesh below are the two it actually meant.
func _exit_tree() -> void:
	for n in _owned:
		if is_instance_valid(n):
			n.queue_free()
	_owned.clear()


## THE CONFIG HOOK. Reads only the four keys this promotion added, checks each word
## against its allow-list, and returns before touching anything when the resulting
## signature is the one already standing. `_config_sig` is primed in _ready() with
## the shipped values, so a call carrying nothing this artifact knows about — which
## is every call the seven exhibit_furniture mounts could ever make — is a strict
## no-op rather than a rebuild. Nothing here rebuilds geometry in any case: all four
## values are read fresh by _process, so a live placement changes shape without a
## single node being freed.
func apply_grid_config(config: Dictionary) -> void:
	var want_crimp: String = crimp
	if config.has("crimp"):
		var w: String = str(config["crimp"])
		if CRIMPS.has(w):
			want_crimp = w
	var want_heading: String = heading
	if config.has("heading"):
		var h: String = str(config["heading"])
		if HEADINGS.has(h):
			want_heading = h
	var want_phase: float = frozen_phase
	if config.has("frozen_phase"):
		want_phase = float(config["frozen_phase"])
	var want_seed: int = wave_seed
	if config.has("wave_seed"):
		want_seed = int(config["wave_seed"])

	var sig: String = _sig(want_crimp, want_heading, want_phase, want_seed)
	if sig == _config_sig:
		return
	_config_sig = sig

	crimp = want_crimp
	heading = want_heading
	frozen_phase = want_phase
	# Redrawn only when the seed itself moved, so a config that repeats the shipped
	# -1 never spends a second randf() and never re-rolls a running flag's phase.
	if want_seed != wave_seed:
		wave_seed = want_seed
		setup_joyful_animation()
