# edge_of_chaos_unlocked.gd
# Reaction-diffusion system with an UNLOCKED lambda slider.
# The companion to the locked-lambda map. Now the learner controls lambda.
#
# @identity
# essence: Gray-Scott reaction-diffusion on a 64x64 grid with an UNLOCKED lambda slider — the control the map withheld, now given
# desire: to answer the critical.md question by letting the learner discover that adjusting lambda IS knowledge and witnessing lambda locked IS knowledge — different kinds
# critical_parameter: lambda (0.0-1.0) — maps to feed/kill rate balance; 0=frozen crystal, 0.4=Turing patterns emerge, 1.0=pure noise
# triggers: dragging lambda slowly from 0 toward 0.4 produces the moment of emergence — spots appear from nothing; pushing past 0.7 dissolves everything into static
# emerges: Turing spots, stripes, labyrinthine patterns at the edge; the learner discovers the parameter space has texture, not just a gradient
# needs: [has] lambda slider via ArtifactControls; [has] regime label (FROZEN/EDGE/CHAOS); [has] display rate control; [missing] no pattern save; no comparison view
# relationships: companion to QFEP_Edge_Of_Chaos map where lambda_slider is locked at 0.4; the map withholds what this artifact gives
# truth: when you control lambda, you understand the parameter space; when you witness it locked, you understand what it feels like to be at the edge; both are knowledge

extends Node3D

class_name EdgeOfChaosUnlocked

const TextScreenScript = preload("res://commons/ui/text_screen.gd")

## Grid resolution for reaction-diffusion
@export var grid_size: int = 64

## Lambda parameter: 0=frozen, 0.4=edge, 1.0=chaos
@export_range(0.0, 1.0, 0.01) var lambda: float = 0.4:
	set(value):
		lambda = clampf(value, 0.0, 1.0)
		_update_reaction_params()
		_update_regime_label()

## Display update rate (frames between texture updates)
@export_range(1, 10) var display_rate: int = 2

## Simulation steps per frame
@export_range(1, 8) var sim_steps: int = 4

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS — tenure
# ═══════════════════════════════════════════════════════════════════
#
# WHO HOLDS LAMBDA, AND AT WHAT SETTING. The truth statement above names two
# states — the knob held and the knob withheld — and the artifact ships one.
# This axis ships both, plus the two poles the parameter space actually has.
#
#   unlocked  the LAMBDA fader is built live at 0.40 on the rack at
#             (1.2, 1.0, 0); the 1.5 x 1.5 m quad carries the Turing
#             spot/stripe field in teal-amber-cream; regime reads
#             EDGE OF CHAOS. This is the pre-promotion look, exactly.
#   clamped   the fader is still built at 0.40, but a 0.34 x 0.05 x 0.03 m
#             brushed-steel bracket is bolted across its travel on two
#             0.05 x 0.09 x 0.016 m gunmetal straps, with two 0.02 m bolt heads
#             at its ends. The straps stay inside the fader's own 0.09 m slot:
#             SIM SPEED and RESEED are not seized and must not look it.
#             The pattern is the SAME spot field and the caption is the SAME
#             caption — a sign still reading UNLOCKED over a bolt driven through
#             the fader IS the value. The companion map's locked slider made an
#             OBJECT instead of a sentence in a relationships line.
#   withheld  the LAMBDA fader is not built at all. A blank
#             0.30 x 0.09 x 0.012 m anthracite blanking plate with four
#             0.012 m rivets fills its slot; the other two controls keep the
#             exact y they have in every other tenure; lambda is held at 0.40
#             so the pattern is unchanged. Where clamped is an object, this one
#             is a SENTENCE — so the sentences are what change. The title reads
#             EDGE OF CHAOS — WITHHELD in anthracite instead of UNLOCKED in
#             green, the caption says the fader is not fitted, and a
#             0.556 x 0.358 m TextScreen stands at (1.12, 0.47, 0) beside the
#             instrument carrying the amendment. The artifact whose whole title
#             is UNLOCKED, shipped locked. This is the value the axis exists for.
#   frozen    the fader is built pushed to its left stop and clamped there.
#             lambda 0.0 -> feed 0.01 / kill 0.08, which is outside the region
#             where B can sustain itself at all, so the 12 seed blots die back
#             to nothing and the quad settles to a FLAT deep-teal field; the
#             regime readout reads FROZEN in blue.
#   chaos     the fader is built at its right stop and clamped. lambda 1.0 ->
#             feed 0.08 / kill 0.03, where B invades every cell it can reach, so
#             the same quad fills edge-to-edge with warm amber-cream and the
#             readout reads CHAOS in red.
#
# ── WHY TWO OF THESE FIVE USED TO BE ONE PICTURE ──────────────────────────────
#
# The critic measured this axis at 17.82% focus — a passing verdict — while two
# of its pairs were twins underneath the mean. Both had the same shape of fault
# and neither was a design fault:
#
#   frozen == chaos (5.87%). The two ENDS of the parameter space, and they
#   photographed the same. Not because the poles were badly chosen but because
#   _simulate_step integrates with the raw 5-point stencil at dt = 1.0, whose
#   worst mode is a checkerboard with eigenvalue -8: explicit Euler needs
#   _diffusion_a * dt < 0.25 there, and _diffusion_a is 0.8 at lambda 0 and 1.2
#   at lambda 1 — over the bound by 3.2x and 4.8x. So BOTH poles diverged to the
#   same clamp-saturated checkerboard within a few dozen steps, and the feed/kill
#   rates, the only thing the poles disagree about, were erased by arithmetic.
#   Measured offline before anything was touched: after 240 steps the two fields
#   differ by 2.2% mean luminance; integrated stably they differ by 48.6%.
#   Fixed by _simulate_step_stable, which the poles alone run — see there.
#
#   clamped == withheld (1.53%). Both are "the fader is not yours" and both said
#   so with a piece of rack hardware about 0.30 m across, on a rack that is 0.9%
#   of the framed picture. Two 0.03 m^2 objects cannot differ by more than the
#   rack itself does. The repair is not a bigger clamp — a clamp on one 0.09 m
#   slot is a small object and pretending otherwise would be a second lie — but
#   moving withheld's evidence to where its meaning already lived: the signage.
#
# NOT swept here: sim_steps and display_rate. Both are exported, both beg to be
# swept, and both photograph as identical stills — a time-domain axis is not
# evidence.
const TENURES: PackedStringArray = ["unlocked", "clamped", "withheld", "frozen", "chaos"]

## Who holds lambda and at what setting.
@export_enum("unlocked", "clamped", "withheld", "frozen", "chaos") var tenure: String = "unlocked"

# Rack slot pitch — must match ArtifactControls._slot_spacing so the blanking
# plate lands exactly where the LAMBDA fader would have been.
const SLOT_PITCH: float = 0.09
const RACK_ORIGIN := Vector3(1.2, 1.0, 0.0)

# Where withheld's amendment notice stands. Chosen to sit INSIDE the artifact's
# existing AABB — x 0.842..1.398 against the readout's own 1.418 right edge,
# y 0.291..0.649 under a rack whose lowest control bottoms out at 0.70 in this
# tenure, clear of the 1.5 m quad that ends at x 0.75. A variant that grows the
# bounding box moves the auto-framing camera, and then every pixel in the frame
# differs for a reason that has nothing to do with the axis.
const NOTICE_ORIGIN := Vector3(1.12, 0.0, 0.0)
const NOTICE_WIDTH: float = 0.52
const NOTICE_HEIGHT: float = 0.47

# The two pole tenures are the only ones whose payload IS the developed field,
# so only they are pre-rolled. clamped/withheld must keep the DEFAULT's frame-1
# spot field — their difference is on the rack and in the signage, never here.
#
# 240 -> 320 because the poles now integrate at STABLE_DT rather than at a
# nominal 1.0: 320 steps is 192 units of model time, which is where the chaos
# front has covered 88% of the grid and frozen has been flat for 100 units. The
# cost is one third more grid passes than before, on two of five tenures.
const PREROLL_STEPS: int = 320

# Timestep for the poles' integration. The stability bound for the normalised
# 5-point laplacian is _diffusion_a * dt < 1; the worst case here is lambda 1.0,
# where _diffusion_a is 1.2, so 0.6 leaves a comfortable margin rather than
# riding the edge and calling the ringing "chaos".
const STABLE_DT: float = 0.6

# Fixed seed: the still has to be the same still every run.
const SEED_RNG: int = 0x5EED17

# Gray-Scott parameters derived from lambda
var _feed_rate: float = 0.037
var _kill_rate: float = 0.06
var _diffusion_a: float = 1.0
var _diffusion_b: float = 0.5

# Grid state (two chemicals: A and B)
var _grid_a: PackedFloat32Array
var _grid_b: PackedFloat32Array
var _grid_a_next: PackedFloat32Array
var _grid_b_next: PackedFloat32Array

# Display
var _texture: ImageTexture
var _image: Image
var _display_quad: MeshInstance3D
var _frame_count: int = 0

# UI
var _controls: Node
var _regime_label: Label3D
var _lambda_label: Label3D
var _title_label: Label3D
var _readout: Node3D
var _notice: Node3D

# Lifecycle
var _built: bool = false
var _authored_lambda: float = 0.4
## Only nodes THIS script created. Freeing get_children() would destroy the
## anthracite plates the label framer adds one deferred call later.
var _owned: Array[Node] = []


func _ready() -> void:
	_authored_lambda = lambda
	tenure = _pick_axis(tenure, TENURES, "unlocked")
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════
#
# Reached via call_deferred AFTER _ready and BEFORE label framing. Note that
# curation_station calls this with {"emissive": false} one line after hiding
# labels — a key this artifact does not claim, so the call falls through both
# early returns and the framing survives. No key is accepted here that does
# not do something.

func apply_grid_config(config_data: Dictionary) -> void:
	var before_tenure: String = tenure
	if config_data.has("tenure"):
		tenure = _pick_axis(str(config_data["tenure"]), TENURES, tenure)

	if not _built:
		return

	if tenure != before_tenure:
		_rebuild_now()
		print("[EdgeOfChaosUnlocked] Config applied — tenure=%s" % [tenure])

	# lambda is applied IN PLACE — its setter re-derives feed/kill and refreshes
	# the readout, so no rebuild is owed. Applied after any tenure rebuild so an
	# explicit lambda wins over the pole tenures' forced value.
	if config_data.has("lambda"):
		lambda = clampf(float(config_data["lambda"]), 0.0, 1.0)


## Accept an axis value only if it names something we actually build. A typo in
## a map token falls back to the legacy look rather than stranding the placement
## with a rack that has neither a fader nor a plate.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## The poles keep integrating the way they were pre-rolled, so the still does not
## depend on when the shutter opens: frozen has reached a fixed point and stays
## there, chaos has reached its uniform high-B state and stays there. Every other
## tenure runs the ORIGINAL stepper, untouched, because that is the picture
## standing in shipped maps.
func _process(delta: float) -> void:
	_frame_count += 1
	var pole: bool = _is_pole()
	for _step in range(sim_steps):
		if pole:
			_simulate_step_stable()
		else:
			_simulate_step()
	if _frame_count % display_rate == 0:
		_update_texture()


# ── Build / rebuild ─────────────────────────────────────────

func _build_all() -> void:
	_apply_tenure_lambda()
	_init_grid()
	_build_display()
	_build_controls()
	_build_labels()
	_update_reaction_params()
	_seed_pattern()
	_preroll()


## SYNCHRONOUS. A deferred rebuild that removes children first makes
## auto-grounding measure a zero AABB and bail.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_display_quad = null
	_controls = null
	_title_label = null
	_regime_label = null
	_lambda_label = null
	_readout = null
	_notice = null
	_texture = null
	_image = null
	_frame_count = 0
	_build_all()


func _own(n: Node) -> void:
	add_child(n)
	_owned.append(n)


## Only the two poles move lambda. unlocked / clamped / withheld all restore the
## value the author set, so a rebuild back off chaos does not strand at 1.0.
func _apply_tenure_lambda() -> void:
	match tenure:
		"frozen":
			lambda = 0.0
		"chaos":
			lambda = 1.0
		_:
			lambda = _authored_lambda


## The two ends of the parameter space, and the only tenures that move lambda.
func _is_pole() -> bool:
	return tenure == "frozen" or tenure == "chaos"


## frozen and chaos are the only tenures whose evidence is the field itself, and
## the field needs frames. Pre-rolling them here makes the still deterministic
## instead of shutter-timing dependent. unlocked, clamped and withheld are NOT
## pre-rolled: they must show the same frame-1 seed field as each other, so the
## only difference between them in the capture is the rack and the signage.
##
## Synchronous by contract, and the cost is bounded: 320 passes over 4096 cells,
## on two tenures out of five, on a grid this artifact was already walking 240
## times at spawn.
func _preroll() -> void:
	if not _is_pole():
		return
	for _i in range(PREROLL_STEPS):
		_simulate_step_stable()
	_update_texture()


# ── Grid Init ───────────────────────────────────────────────

func _init_grid() -> void:
	var total := grid_size * grid_size
	_grid_a = PackedFloat32Array()
	_grid_b = PackedFloat32Array()
	_grid_a_next = PackedFloat32Array()
	_grid_b_next = PackedFloat32Array()
	_grid_a.resize(total)
	_grid_b.resize(total)
	_grid_a_next.resize(total)
	_grid_b_next.resize(total)

	# Fill with chemical A=1, B=0
	for i in range(total):
		_grid_a[i] = 1.0
		_grid_b[i] = 0.0


func _seed_pattern() -> void:
	# Seed a few spots of chemical B in the center region.
	# Fixed seed — five tenure stills have to be comparable, which means the
	# blots have to land in the same twelve places every run.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED_RNG
	var center := grid_size / 2
	var radius := grid_size / 8
	for _s in range(12):
		var sx := center + rng.randi_range(-radius, radius)
		var sz := center + rng.randi_range(-radius, radius)
		for dx in range(-2, 3):
			for dz in range(-2, 3):
				var x := clampi(sx + dx, 0, grid_size - 1)
				var z := clampi(sz + dz, 0, grid_size - 1)
				var idx := z * grid_size + x
				_grid_b[idx] = 1.0
				_grid_a[idx] = 0.5


# ── Reaction-Diffusion ─────────────────────────────────────

func _update_reaction_params() -> void:
	# Map lambda to Gray-Scott feed/kill parameter space
	# lambda=0: very low feed, high kill -> frozen, nothing grows
	# lambda~0.4: feed=0.037, kill=0.06 -> Turing patterns (spots/stripes)
	# lambda=1: high feed, low kill -> everything activates, noise
	_feed_rate = lerpf(0.01, 0.08, lambda)
	_kill_rate = lerpf(0.08, 0.03, lambda)
	_diffusion_a = lerpf(0.8, 1.2, lambda)
	_diffusion_b = lerpf(0.3, 0.7, lambda)


func _simulate_step() -> void:
	var dt := 1.0
	var gs := grid_size

	for z in range(gs):
		for x in range(gs):
			var idx := z * gs + x

			var a := _grid_a[idx]
			var b := _grid_b[idx]

			# Laplacian (5-point stencil with wrapping)
			var lap_a := -4.0 * a
			var lap_b := -4.0 * b

			var xl := ((x - 1) + gs) % gs
			var xr := (x + 1) % gs
			var zu := ((z - 1) + gs) % gs
			var zd := (z + 1) % gs

			lap_a += _grid_a[z * gs + xl] + _grid_a[z * gs + xr] + _grid_a[zu * gs + x] + _grid_a[zd * gs + x]
			lap_b += _grid_b[z * gs + xl] + _grid_b[z * gs + xr] + _grid_b[zu * gs + x] + _grid_b[zd * gs + x]

			# Gray-Scott equations
			var ab2 := a * b * b
			var new_a := a + (_diffusion_a * lap_a - ab2 + _feed_rate * (1.0 - a)) * dt
			var new_b := b + (_diffusion_b * lap_b + ab2 - (_kill_rate + _feed_rate) * b) * dt

			_grid_a_next[idx] = clampf(new_a, 0.0, 1.0)
			_grid_b_next[idx] = clampf(new_b, 0.0, 1.0)

	# Swap buffers
	var temp_a := _grid_a
	var temp_b := _grid_b
	_grid_a = _grid_a_next
	_grid_b = _grid_b_next
	_grid_a_next = temp_a
	_grid_b_next = temp_b


## THE SAME EQUATIONS AT A STEP THEY SURVIVE. Run by frozen and chaos only.
##
## _simulate_step above applies the raw 5-point laplacian (centre weight -4) with
## dt = 1.0. Explicit Euler on a diffusion term is stable only while D * dt times
## the operator's largest eigenvalue stays under 2; that operator's worst mode is
## the checkerboard at -8, so the bound is D * dt < 0.25 and _diffusion_a runs
## 0.8 to 1.2 — over by 3.2x at lambda 0 and 4.8x at lambda 1, unstable at BOTH
## ends and everywhere between. The state saturates against the 0..1 clamp,
## and a saturated checkerboard is the same picture whatever feed and kill are.
## That is the whole reason the two poles were twins: not a design that failed to
## distinguish them, an integrator that threw the distinction away.
##
## Two changes, both arithmetic, neither touching what the values MEAN:
##   * the laplacian is NORMALISED (mean of the four neighbours minus the centre,
##     i.e. the same operator scaled by 1/4), the conventional Gray-Scott form;
##   * dt is STABLE_DT rather than 1.0.
## Together they put the worst case at 1.2 * 0.6 = 0.72, inside the bound with
## room to spare, and the poles then land where the parameters say they should:
## lambda 0 has no sustaining solution for B, so the seed blots decay and the
## field goes flat deep teal; lambda 1 has a stable high-B state at B = 0.59, so
## B invades the whole grid and the field goes warm amber-cream.
##
## Deliberately NOT applied to unlocked, clamped or withheld. Those three stand
## in shipped maps and the default's picture is not mine to improve here.
func _simulate_step_stable() -> void:
	var gs: int = grid_size

	for z in range(gs):
		for x in range(gs):
			var idx: int = z * gs + x

			var a: float = _grid_a[idx]
			var b: float = _grid_b[idx]

			var xl: int = ((x - 1) + gs) % gs
			var xr: int = (x + 1) % gs
			var zu: int = ((z - 1) + gs) % gs
			var zd: int = (z + 1) % gs

			var lap_a: float = (_grid_a[z * gs + xl] + _grid_a[z * gs + xr] \
					+ _grid_a[zu * gs + x] + _grid_a[zd * gs + x]) * 0.25 - a
			var lap_b: float = (_grid_b[z * gs + xl] + _grid_b[z * gs + xr] \
					+ _grid_b[zu * gs + x] + _grid_b[zd * gs + x]) * 0.25 - b

			var ab2: float = a * b * b
			var new_a: float = a + (_diffusion_a * lap_a - ab2 \
					+ _feed_rate * (1.0 - a)) * STABLE_DT
			var new_b: float = b + (_diffusion_b * lap_b + ab2 \
					- (_kill_rate + _feed_rate) * b) * STABLE_DT

			_grid_a_next[idx] = clampf(new_a, 0.0, 1.0)
			_grid_b_next[idx] = clampf(new_b, 0.0, 1.0)

	var temp_a: PackedFloat32Array = _grid_a
	var temp_b: PackedFloat32Array = _grid_b
	_grid_a = _grid_a_next
	_grid_b = _grid_b_next
	_grid_a_next = temp_a
	_grid_b_next = temp_b


# ── Display ─────────────────────────────────────────────────

func _build_display() -> void:
	_image = Image.create(grid_size, grid_size, false, Image.FORMAT_RGB8)
	_texture = ImageTexture.create_from_image(_image)

	_display_quad = MeshInstance3D.new()
	_display_quad.name = "ReactionDiffusionDisplay"

	var quad := QuadMesh.new()
	quad.size = Vector2(1.5, 1.5)
	_display_quad.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _texture
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_display_quad.material_override = mat

	# Tilt the quad to face the viewer
	_display_quad.position = Vector3(0, 0.85, 0)
	_display_quad.rotation_degrees.x = -15
	_own(_display_quad)

	# Base
	var base := MeshInstance3D.new()
	base.name = "Base"
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 0.06, 0.3)
	base.mesh = box
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.1, 0.1, 0.12)
	bmat.metallic = 0.5
	bmat.roughness = 0.4
	base.material_override = bmat
	base.position = Vector3(0, 0.03, 0)
	_own(base)


func _update_texture() -> void:
	for z in range(grid_size):
		for x in range(grid_size):
			var idx := z * grid_size + x
			var b_val := _grid_b[idx]

			# Turing pattern palette:
			# Low B (no pattern) -> deep teal
			# Medium B (edge patterns) -> warm amber/green
			# High B (active) -> bright cream
			var col: Color
			if b_val < 0.15:
				col = Color(0.05, 0.15, 0.18).lerp(Color(0.1, 0.3, 0.25), b_val / 0.15)
			elif b_val < 0.4:
				var t := (b_val - 0.15) / 0.25
				col = Color(0.1, 0.3, 0.25).lerp(Color(0.7, 0.55, 0.2), t)
			else:
				var t := clampf((b_val - 0.4) / 0.6, 0.0, 1.0)
				col = Color(0.7, 0.55, 0.2).lerp(Color(0.95, 0.9, 0.8), t)

			_image.set_pixel(x, z, col)

	_texture.update(_image)


# ── Controls ────────────────────────────────────────────────

func _build_controls() -> void:
	_controls = ArtifactControls.new()
	_controls.name = "Controls"
	if tenure == "withheld":
		# Slot 0 is left empty for the blanking plate. Push the whole rack down
		# one pitch so SIM SPEED and RESEED keep the exact y they hold in every
		# other tenure — the rack must read as the SAME rack, minus one control.
		_controls.position = RACK_ORIGIN + Vector3(0.0, -SLOT_PITCH, 0.0)
	else:
		_controls.position = RACK_ORIGIN
	_own(_controls)

	if tenure != "withheld":
		_controls.add_slider("LAMBDA", lambda, func(v: float):
			# unlocked is the only tenure where the fader writes anything. On
			# clamped / frozen / chaos the bracket is bolted across its travel,
			# so the handle is hardware, not a control.
			if tenure == "unlocked":
				lambda = v
		)

	_controls.add_slider("SIM SPEED", float(sim_steps - 1) / 7.0, func(v: float):
		sim_steps = int(round(v * 7.0)) + 1
	)
	_controls.add_button("RESEED", func():
		_init_grid()
		_seed_pattern()
	)

	match tenure:
		"clamped", "frozen", "chaos":
			_own(_build_clamp_bracket())
		"withheld":
			_own(_build_blanking_plate())


## A bar bolted across the LAMBDA fader's travel. Wider than the 0.18 m fader
## because it has to reach past it to the rack on either side — that overhang is
## what makes it read as a clamp and not as a second control.
func _build_clamp_bracket() -> Node3D:
	var node := Node3D.new()
	node.name = "LambdaClamp"
	node.position = RACK_ORIGIN

	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.62, 0.63, 0.65)
	steel.metallic = 0.85
	steel.roughness = 0.35

	var bar := MeshInstance3D.new()
	bar.name = "Bracket"
	var bar_box := BoxMesh.new()
	bar_box.size = Vector3(0.34, 0.05, 0.03)
	bar.mesh = bar_box
	bar.material_override = steel
	# The rack chassis is 0.02 deep and its lit screen quad sits at z = 0.011,
	# so the bar clears the glyphs it is holding shut.
	bar.position = Vector3(0.0, 0.0, 0.030)
	node.add_child(bar)

	# Feet. A bar floating across a fader is a bar; a bar on straps that reach the
	# chassis is a clamp. Held to 0.09 m tall — the fader's own slot pitch — so the
	# assembly never reads as seizing SIM SPEED or RESEED, which are still live.
	var gunmetal := StandardMaterial3D.new()
	gunmetal.albedo_color = Color(0.22, 0.23, 0.25)
	gunmetal.metallic = 0.7
	gunmetal.roughness = 0.45

	for i in range(2):
		var strap_side: float = -1.0 if i == 0 else 1.0
		var strap := MeshInstance3D.new()
		strap.name = "Strap%s" % ("L" if i == 0 else "R")
		var strap_box := BoxMesh.new()
		strap_box.size = Vector3(0.05, 0.09, 0.016)
		strap.mesh = strap_box
		strap.material_override = gunmetal
		strap.position = Vector3(0.15 * strap_side, 0.0, 0.020)
		node.add_child(strap)

	var bolt_steel := StandardMaterial3D.new()
	bolt_steel.albedo_color = Color(0.48, 0.49, 0.52)
	bolt_steel.metallic = 0.9
	bolt_steel.roughness = 0.28

	for i in range(2):
		var side: float = -1.0 if i == 0 else 1.0
		var bolt := MeshInstance3D.new()
		bolt.name = "Bolt%s" % ("L" if i == 0 else "R")
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.010
		cyl.bottom_radius = 0.010
		cyl.height = 0.020
		bolt.mesh = cyl
		bolt.material_override = bolt_steel
		bolt.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		bolt.position = Vector3(0.15 * side, 0.0, 0.048)
		node.add_child(bolt)

	return node


## No fader. A riveted blank in its slot — the sequence's politics as an object.
## Anthracite is deliberately the label framer's own panel colour: the plate and
## the framed captions read as the same institutional material.
func _build_blanking_plate() -> Node3D:
	var node := Node3D.new()
	node.name = "LambdaBlankingPlate"
	node.position = RACK_ORIGIN

	var anthracite := StandardMaterial3D.new()
	anthracite.albedo_color = Color(0.12, 0.12, 0.135)
	anthracite.metallic = 0.2
	anthracite.roughness = 0.55

	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var box := BoxMesh.new()
	box.size = Vector3(0.30, 0.09, 0.012)
	plate.mesh = box
	plate.material_override = anthracite
	plate.position = Vector3(0.0, 0.0, 0.012)
	node.add_child(plate)

	var rivet_mat := StandardMaterial3D.new()
	rivet_mat.albedo_color = Color(0.34, 0.34, 0.36)
	rivet_mat.metallic = 0.8
	rivet_mat.roughness = 0.4

	for i in range(4):
		var sx: float = -1.0 if (i % 2) == 0 else 1.0
		var sy: float = -1.0 if i < 2 else 1.0
		var rivet := MeshInstance3D.new()
		rivet.name = "Rivet%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.006
		cyl.bottom_radius = 0.006
		cyl.height = 0.008
		rivet.mesh = cyl
		rivet.material_override = rivet_mat
		rivet.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		rivet.position = Vector3(0.13 * sx, 0.032 * sy, 0.020)
		node.add_child(rivet)

	return node


# ── Labels ──────────────────────────────────────────────────
#
# TWO hanging Label3Ds remain, and both are meant to be framed by
# GridInteractablesComponent at spawn: title and subtitle. Their y positions are
# chosen for the OPAQUE plate the framer builds behind them (text width + 0.05,
# height + 0.035), not for the see-through glyphs the old capture harness drew.
#
# The two live readouts are NOT hanging labels any more. Framed, they became a
# 1.05 x 0.21 m plate centred at floor level and a 0.77 x 0.18 m plate centred
# 0.15 m BELOW the floor, standing 0.19 m in front of the 1.6 x 0.06 x 0.3 m
# base and masking its whole front face from any camera below eye height. They
# are promoted to one TextScreen on the rack side instead.

## WITHHELD IS THE ONE TENURE WHOSE SUBJECT IS THIS TEXT. Every other value can
## leave the caption alone, and clamped MUST: a sign reading UNLOCKED above a
## bolted fader is the contradiction that value is made of. But an artifact that
## does not fit the control cannot go on advertising it in 36 pt, and the axis
## doc has said so in words since the day it was written — "the artifact whose
## whole title is UNLOCKED, shipped locked". So under withheld the title says
## WITHHELD and goes anthracite, and the caption underneath stops promising the
## slider. Same character count as UNLOCKED, deliberately: LabelFramer sizes one
## shared plate from the widest line it measures, and a longer word would move
## furniture that four other tenures share.
func _build_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "Title"
	_title_label.text = "EDGE OF CHAOS — WITHHELD" if tenure == "withheld" \
			else "EDGE OF CHAOS — UNLOCKED"
	_title_label.font_size = 36
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# KEPT. Framed plate ~1.72 x 0.25 m spans y 1.875–2.125; the display quad's
	# top edge is at (0, 1.574, -0.194), so it clears the artwork by 0.30 m.
	_title_label.position = Vector3(0, 2.0, 0)
	_title_label.modulate = Color(0.42, 0.44, 0.46, 0.9) if tenure == "withheld" \
			else Color(0.4, 1.0, 0.6, 0.9)
	_own(_title_label)

	var sub := Label3D.new()
	sub.name = "Subtitle"
	# EXACTLY 45 characters, the same as the line it replaces, and the replaced
	# tail is the same 17 characters as " Now it is yours." LabelFramer sizes one
	# shared plate from the widest line in the stack, and this stack is close
	# enough between its two lines that a longer caption could take over as the
	# widest — widening the plate, widening the AABB, and pulling the auto-framing
	# camera back for this tenure alone. A variant that re-frames the shot is not
	# a variant, it is a different photograph.
	sub.text = "The slider the map withheld. Not fitted here." \
			if tenure == "withheld" else "The slider the map withheld. Now it is yours."
	sub.font_size = 20
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# MOVED 1.85 -> 1.76. At 1.85 the framed plate spanned 1.765–1.935 and
	# shingled 0.06 m into the title plate's bottom edge at 1.875 — two
	# anthracite slabs overlapping. At 1.76 it spans 1.675–1.845: 0.03 m clear
	# under the title, 0.10 m clear above the display's top edge.
	sub.position = Vector3(0, 1.76, 0)
	sub.modulate = Color(0.7, 0.8, 0.7, 0.7)
	_own(sub)

	_build_readout()
	if tenure == "withheld":
		_notice = _build_withheld_notice()
		_own(_notice)
	_update_regime_label()


## The regime word and the lambda value on ONE TextScreen (SCREEN mode), parked
## above the control rack and just outboard of the display quad's right edge.
## Board 0.636 x 0.41 m: x 0.782–1.418 (quad ends at 0.75), y 1.215–1.625 (rack
## top ~1.03). Nothing in the viewing corridor.
func _build_readout() -> void:
	_readout = Node3D.new()
	_readout.name = "ReadoutHolder"
	_readout.position = Vector3(1.10, 1.42, 0.02)
	_own(_readout)

	# Deliberately untyped: the script is preloaded rather than reached through
	# its class_name, which is what keeps it resolvable headless.
	var screen = TextScreenScript.new()
	screen.name = "RegimeScreen"
	screen.mode = 0                     # TextScreen.Mode.SCREEN
	screen.width_m = 0.60
	screen.title = "EDGE OF CHAOS"
	screen.body = "lambda = %.2f" % lambda
	_readout.add_child(screen)

	# The Label3D nodes survive as the text source so anything reading .text
	# keeps working, but they hang on nothing now: billboard DISABLED means the
	# framer skips them (its own skip rule), and invisible means they add no
	# glyphs and no AABB of their own to the camera's framing.
	_regime_label = Label3D.new()
	_regime_label.name = "RegimeLabel"
	_regime_label.font_size = 28
	_regime_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_regime_label.visible = false
	_regime_label.position = Vector3.ZERO
	_readout.add_child(_regime_label)

	_lambda_label = Label3D.new()
	_lambda_label.name = "LambdaValue"
	_lambda_label.font_size = 22
	_lambda_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_lambda_label.visible = false
	_lambda_label.position = Vector3(0, -0.05, 0)
	_lambda_label.modulate = Color(0.8, 0.8, 0.8, 0.7)
	_readout.add_child(_lambda_label)


## The amendment, standing beside the instrument. withheld only.
##
## WHY A WHOLE OBJECT AND NOT A BIGGER BLANKING PLATE. The blanking plate says
## the true thing in the true place, and at the scale a viewer meets this
## artifact it is 0.027 m^2 on a rack that is under 1% of the picture — which is
## why clamped and withheld measured as one picture at 1.53% focus. The answer is
## not to inflate rack hardware until it photographs (a clamp the size of the
## instrument would be a second false declaration). It is that the two values
## differ in KIND, and the doc already says how: clamped is an object, withheld
## is a sentence — the artifact still calling itself UNLOCKED while shipping
## locked. A sentence in this project gets a body, and the body is TextScreen.
##
## 0.556 x 0.358 m of framed dark glass on a 0.31 m post, standing in the empty
## floor space between the display quad's right edge and the rack. Kept strictly
## inside the existing AABB — see NOTICE_ORIGIN.
func _build_withheld_notice() -> Node3D:
	var node := Node3D.new()
	node.name = "WithheldNotice"
	node.position = NOTICE_ORIGIN

	# Untyped for the same reason the readout is: preloaded rather than reached
	# through class_name, which is what keeps it resolvable headless.
	var screen = TextScreenScript.new()
	screen.name = "AmendmentScreen"
	screen.mode = 1                     # TextScreen.Mode.STAND
	screen.width_m = NOTICE_WIDTH
	screen.stand_height = NOTICE_HEIGHT
	screen.title = "LAMBDA WITHHELD"
	screen.body = "fader not fitted\nheld at %.2f" % lambda
	node.add_child(screen)
	return node


func _update_regime_label() -> void:
	if not _regime_label:
		return
	var word: String = "EDGE OF CHAOS"
	var tint: Color = Color(0.2, 1.0, 0.5, 0.9)
	if lambda < 0.2:
		word = "FROZEN"
		tint = Color(0.4, 0.6, 1.0, 0.9)
	elif lambda >= 0.55:
		word = "CHAOS"
		tint = Color(1.0, 0.3, 0.2, 0.9)

	_regime_label.text = word
	_regime_label.modulate = tint

	var value_line: String = _lambda_line()
	if _lambda_label:
		_lambda_label.text = value_line

	if _readout and is_instance_valid(_readout):
		var screen = _readout.get_node_or_null("RegimeScreen")
		if screen:
			screen.title_color = tint
			screen.set_text(word, value_line)


## The value, and who is allowed to move it. Costs nothing in the still — the
## readout's body line is about 60 x 8 px at capture scale — and is not why the
## twin is fixed. It is here so a person standing in front of the instrument can
## read the same fact the axis declares, instead of inferring it from a bolt.
func _lambda_line() -> String:
	var line: String = "lambda = %.2f" % lambda
	match tenure:
		"clamped":
			return line + "  HELD"
		"withheld":
			return line + "  NO FADER"
		"frozen", "chaos":
			return line + "  AT STOP"
	return line
