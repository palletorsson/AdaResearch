@tool
extends Node3D

# Parametric Pendulum Waves
# Array of pendulums with carefully chosen lengths creating wave patterns
# Famous physics demonstration: "pendulum snake" or "pendulum wave"
#
# ── THE REPAIR (2026-09-16) ─────────────────────────────────────────────────────
# This rig could not phase, for three reasons that each hid the others:
#
#   1. EVERY LENGTH WAS ONE LENGTH. The periods were set for 51..65 swings in 60 s, which
#      asks for pendulums 0.34 m down to 0.21 m, and then each length was clamped to
#      [shortest_length, longest_length] = [0.8, 1.5]. All fifteen became 0.8 m and swung as
#      one pendulum. The clamp is gone. The swing counts are now DERIVED from the length
#      window (_derive_setting_out) and nothing is ever clamped.
#   2. THE SWING PLANE RAN ALONG THE ROW. The bobs swung in X, the axis the pivots are spaced
#      along, at amplitudes (0.4-0.7 m) larger than the spacing (0.3 m), so neighbours passed
#      through one another and no snake could form. They swing in Z now, across the bar, as
#      every pendulum wave does.
#   3. DAMPING WAS PER FRAME. `angular_velocity *= damping` once a frame lost 11% a second at
#      60 fps and more at 90 or 120, so the amplitude had fallen to ~3% before the first
#      return to unison, and a headset lost it faster than a desktop. It is exponential in
#      TIME now and the motion is advanced exactly, so any frame rate gives the same swing.
#
# DEFAULTS THAT CHANGED, and why a broken default is not sacred: no export default changed
# value. What changed is what the defaults DO — 15 lengths from 1.500 m to 0.801 m instead of
# fifteen copies of 0.800 m, a cycle of 93.4 s instead of a stated 60 s that never happened,
# a swing across the bar, and `damping` read as the fraction of amplitude kept per SECOND.
# The old per-frame reading of 0.998 left nothing to watch. Read per second, the swing sinks
# to 91% of its height by mid-cycle and, with relaunch_each_cycle on (the default), is given
# back on the way home, so the bobs ARRIVE at unison at full height and nothing jumps there;
# with relaunch off it keeps sinking, 83% at the first unison. No placement token sets any of
# these (apply_grid_config reads only `armature`), so every live placement changes the same
# way: from a rig that could not do the one thing it is for, to one that does.

@export_group("Pendulum Array")
@export var num_pendulums: int = 15
@export var pendulum_spacing: float = 0.3
@export var base_height: float = 2.5

@export_group("Length Variation")
## The WINDOW the lengths are set out in. The longest pendulum hangs exactly longest_length
## and every other length is derived from the swing counts; none is clamped, because a clamp
## gives two pendulums one length and one rate, and the unison never comes back.
@export var shortest_length: float = 0.8
@export var longest_length: float = 1.5
@export var length_profile: String = "Linear"  # Linear, Quadratic, or Custom (unused: the swing counts set the profile)
## Seconds from unison to unison. 0 (the default) DERIVES it from the window: the fewest
## swings that let N consecutive counts fit between shortest and longest. A positive value
## fixes the cycle instead and derives the longest pendulum that fits under longest_length;
## if the shortest then falls below shortest_length the rig says so loudly and keeps the
## true lengths.
@export var cycle_time: float = 0.0

@export_group("Physics")
@export var gravity: float = 9.8
## Fraction of the swing's amplitude kept per SECOND of decay (1.0 = no loss). Applied as
## exp(-k * delta) with k = -ln(damping), so it is the same at 30, 72, 90 or 120 fps. With
## relaunch_each_cycle on, the loss runs out to mid-cycle and is given back by unison.
@export var damping: float = 0.998
@export var release_all: bool = false  # Release all pendulums at once
## Every cycle starts again at full height, the way a demonstrator re-releases a real rig.
## On, the height lost on the way out to mid-cycle is given back on the way home (amplitude
## exp(-k * min(t, T - t))), so the bobs ARRIVE at unison at release_angle and the relaunch
## has nothing to lift: no jump at the one moment the rig exists to show. It scales the
## amplitude only and never the phase. Off, the swing decays as exp(-k * t) and never restarts.
@export var relaunch_each_cycle: bool = true

@export_group("Visualization")
@export var bob_radius: float = 0.08
@export var rod_thickness: float = 0.02
@export var show_pivot_bar: bool = true
@export var trail_length: int = 100
@export var color_by_index: bool = true

@export_group("Animation")
@export var auto_release: bool = true
@export var release_angle: float = 0.5  # Initial angle in radians (about 30°)
@export var show_phase_info: bool = true

@export_group("DNA")
## AXIS — WHAT OF THE SETTING-OUT IS STILL STANDING. A pendulum wave is not a discovery, it
## is a piece of arithmetic built in steel: fifteen lengths chosen so the periods form an
## arithmetic sequence, and the "wave" that runs along the bobs is an artefact of that
## choice, not a property of pendulums. The shipped rig shows a plain grey bar and hides
## every trace of the calculation, so the wave arrives looking like nature. A rig that shows
## its setting-out admits the pattern was SET OUT, by someone, to a measure.
##
## Adopted word for word — and value for value — from [[facade_builder]], which asks the
## identical question of a composed elevation ("what of the making is still standing on the
## finished face"). Same word, same four moments, because a room holding a facade whose
## construction grid is still drawn on it should not hold a pendulum rig that pretends it
## grew.
##
##   none      the legacy lineage — the pivot bar alone, no apparatus
##   datum     the setting-out lines left on the rig: a back-board carrying the pivot datum,
##             a station tick under every pendulum, and the LENGTH LADDER drawn as a stepped
##             rule that touches each bob's rest height in turn — the arithmetic built
##             instead of erased
##   scaffold  the working platform still up — standards, two lifts of ledgers, a board deck
##             and toe board running the whole front at waist height, the rig caught
##             mid-erection with the bobs swinging over the boards
##   gantry    the lifting frame: two towers standing past the ends of the bar, a head beam
##             over the top and a hoist block on a chain between the two middle stations —
##             the machinery that PUT the bobs at those lengths, not the array that resulted
##
## STRICTLY ADDITIVE and appearance only. "none" builds nothing at all and is the default.
## Nothing here touches the length formula, the periods, the release, the damping or the
## integration — it is staged AROUND the array and stops there. Since the 2026-09-16 repair
## the board and the scaffold rows stand clear of the swing ACROSS the bar, measured from
## the built lengths (_swing_reach), not at fixed offsets that the bobs now pass through.
@export_enum("none", "datum", "scaffold", "gantry") var armature: String = "none"
const ARMATURES: PackedStringArray = ["none", "datum", "scaffold", "gantry"]

const G_FALLBACK := 9.8
const TEXT_SCREEN_SCRIPT := preload("res://commons/ui/text_screen.gd")
const CAPTION_W := 1.0           # metres; TextScreen makes it 0.62 m tall
const CAPTION_Y := 1.45          # caption centre, reading height
const PANEL_Y := 0.98            # the RELEASE button's panel centre, hand height
const PANEL_SCALE := 1.6

# Internal data
var pendulums: Array[Dictionary] = []
var time_since_release: float = 0.0
var is_released: bool = false
var trail_points: Array[Array] = []

var _built: bool = false
var _cycle: float = 0.0           # seconds from unison to unison, as BUILT
var _first_swings: int = 0        # full swings of the longest pendulum per cycle
var _decay_k: float = 0.0         # amplitude decay rate, 1/s
# Untyped on purpose: _exit_tree frees these, and a typed read of a freed instance errors.
var _owned: Array = []            # every node this script built, except the armature host
var _containers: Array = []
var _bobs: Array = []
var _rods: Array = []
var _caption: Node3D = null
var _panel: Node3D = null


func _ready() -> void:
	if _built:
		return
	_build()


func _build() -> void:
	_built = true
	var _a: String = str(armature).strip_edges().to_lower()
	armature = _a if ARMATURES.has(_a) else "none"
	_build_pendulum_array()
	_build_stand()
	if auto_release:
		_release_pendulums()
	else:
		_update_visualization()
	# DNA, LAST: the armature is appended after the whole array exists. "none" builds nothing.
	_build_armature()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if release_all:
		_release_pendulums()
		release_all = false

	if is_released:
		step(delta)
		_update_visualization()


# ── THE SETTING-OUT ──────────────────────────────────────────────────────────
# Over one cycle of T seconds pendulum i makes n0 + i full swings, so its period is
# T / (n0 + i) and, from T = 2π√(L/g), its length is L = g · (T / (2π (n0 + i)))².
# Consecutive integer counts are the whole trick: after T every pendulum has made a
# whole number of swings, so all are back where they started together — unison — and
# in between, pendulum i leads its neighbour by one swing per cycle, so the row runs
# through a travelling snake, two interleaved rows at T/2, three at T/3, and stretches
# no eye can parse, which is the apparent disorder.

func _derive_setting_out() -> void:
	var n: int = maxi(num_pendulums, 1)
	var g: float = gravity if gravity > 0.0 else G_FALLBACK
	var hi: float = maxf(shortest_length, longest_length)
	var lo: float = minf(shortest_length, longest_length)
	if hi <= 0.0:
		push_warning("parametric_pendulum_waves: longest_length %.3f is not a length — using 1.5 m" % longest_length)
		hi = 1.5
	if n > 1 and (lo <= 0.0 or lo >= hi):
		push_warning("parametric_pendulum_waves: the window [%.3f, %.3f] m has no room for %d DISTINCT lengths — using [%.3f, %.3f] m" % [shortest_length, longest_length, n, hi * 0.5, hi])
		lo = hi * 0.5

	if cycle_time > 0.0:
		_cycle = cycle_time
		# the fewest swings whose length still hangs no longer than the window allows
		_first_swings = maxi(1, int(ceil(_cycle / TAU * sqrt(g / hi) - 1e-9)))
	else:
		if n > 1:
			# ((n0 + N - 1) / n0)² <= hi / lo  ->  n0 >= (N - 1) / (√(hi/lo) - 1)
			_first_swings = maxi(1, int(ceil(float(n - 1) / (sqrt(hi / lo) - 1.0) - 1e-9)))
		else:
			_first_swings = 1
		# and the cycle that makes the longest pendulum exactly the longest length
		_cycle = TAU * float(_first_swings) * sqrt(hi / g)

	var longest: float = g * pow(_cycle / (TAU * float(_first_swings)), 2.0)
	var shortest: float = g * pow(_cycle / (TAU * float(_first_swings + n - 1)), 2.0)
	if shortest < lo * (1.0 - 1e-6) or longest > hi * (1.0 + 1e-6):
		push_warning(("parametric_pendulum_waves: a %.1f s cycle with %d..%d swings needs lengths %.3f..%.3f m, "
			+ "OUTSIDE the window [%.3f, %.3f] m. The true lengths are kept and NOT clamped: a clamp "
			+ "gives two pendulums one length and the unison never returns.")
			% [_cycle, _first_swings, _first_swings + n - 1, longest, shortest, lo, hi])
	if _cycle > 600.0:
		push_warning("parametric_pendulum_waves: the window [%.3f, %.3f] m for %d pendulums makes a %.0f s cycle — widen it or set cycle_time" % [lo, hi, n, _cycle])

	_decay_k = -log(clampf(damping, 0.0001, 1.0))


func _build_pendulum_array() -> void:
	_clear_owned()
	pendulums.clear()
	trail_points.clear()
	_containers.clear()
	_bobs.clear()
	_rods.clear()

	# Create pivot bar
	if show_pivot_bar:
		_create_pivot_bar()

	_derive_setting_out()
	var g: float = gravity if gravity > 0.0 else G_FALLBACK
	var n: int = maxi(num_pendulums, 1)

	for i in range(n):
		var swings: int = _first_swings + i
		var period: float = _cycle / float(swings)
		# From T = 2π√(L/g):  L = g · (T / 2π)²
		var length: float = g * pow(period / TAU, 2.0)

		var pendulum_data := {
			"index": i,
			"length": length,
			"angle": 0.0,  # Current angle (radians), across the bar
			"angular_velocity": 0.0,
			"angular_acceleration": 0.0,
			"oscillations": float(swings),
			"swings": swings,
			"period": period,
			"omega": TAU / period,
			"pivot_position": Vector3(
				(i - (n - 1) / 2.0) * pendulum_spacing,
				base_height,
				0.0
			)
		}

		pendulums.append(pendulum_data)
		trail_points.append([])

		# Create visual components
		_create_pendulum_visual(pendulum_data)


func _clear_owned() -> void:
	for node in _owned:
		if is_instance_valid(node):
			if node.get_parent() == self:
				remove_child(node)    # detach NOW, so the rebuilt names are not suffixed
			node.queue_free()
	_owned.clear()
	_caption = null
	_panel = null


func _own(node: Node) -> void:
	add_child(node)
	_owned.append(node)


func _create_pivot_bar() -> void:
	"""Create horizontal bar showing pivot points"""
	var bar_width = num_pendulums * pendulum_spacing + pendulum_spacing
	var bar = MeshInstance3D.new()
	bar.name = "PivotBar"

	var box = BoxMesh.new()
	box.size = Vector3(bar_width, 0.05, 0.05)
	bar.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.3)
	mat.metallic = 0.0
	mat.roughness = 1.0
	bar.material_override = mat

	bar.position = Vector3(0, base_height, 0)
	_own(bar)


func _create_pendulum_visual(pend: Dictionary) -> void:
	"""Create rod and bob for pendulum"""
	var container := Node3D.new()
	container.name = "Pendulum_%d" % int(pend["index"])
	container.position = pend["pivot_position"]
	_own(container)

	# Bob (sphere at end)
	var bob := MeshInstance3D.new()
	bob.name = "Bob"

	var sphere := SphereMesh.new()
	sphere.radius = bob_radius
	sphere.height = bob_radius * 2.0
	bob.mesh = sphere

	var color: Color
	if color_by_index:
		var hue: float = float(pend["index"]) / float(maxi(num_pendulums, 1))
		color = Color.from_hsv(hue, 0.8, 1.0)
	else:
		color = Color(0.9, 0.3, 0.3)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.5
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.0
	mat.roughness = 1.0
	bob.material_override = mat

	container.add_child(bob)

	# Rod (cylinder from pivot to bob)
	var rod := MeshInstance3D.new()
	rod.name = "Rod"

	var cylinder := CylinderMesh.new()
	cylinder.top_radius = rod_thickness
	cylinder.bottom_radius = rod_thickness
	cylinder.height = float(pend["length"])
	rod.mesh = cylinder

	var rod_mat := StandardMaterial3D.new()
	rod_mat.albedo_color = Color(0.5, 0.5, 0.5, 0.7)
	rod_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rod_mat.metallic = 0.0
	rod_mat.roughness = 1.0
	rod.material_override = rod_mat

	container.add_child(rod)

	_containers.append(container)
	_bobs.append(bob)
	_rods.append(rod)


# ── MOTION ───────────────────────────────────────────────────────────────────
# The lengths are computed with the small-angle period, so the motion uses the same model:
# θ'' = -(g/L) θ. It is advanced EXACTLY, as a rotation of (θ, θ'/ω) through ω·dt, not by
# an Euler step, so a 1/30 s frame and four 1/120 s frames land on the same state and a whole
# cycle lands every pendulum back on its release. A large-angle sin(θ) model would stretch
# every period by ~1.6% at 0.5 rad and move the unison off the time this rig announces.
#
# Damping multiplies the amplitude by an ENVELOPE ratio, env(t + h) / env(t), which commutes
# with the rotation, so it never moves a phase and any split of the steps lands on the same
# state. env(t) = exp(-k t) with relaunch off; exp(-k min(t, T - t)) with it on, so the
# swing is back at full height when the unison arrives and the relaunch only resets the
# clock (and whatever rounding the clock carried).

func _release_pendulums() -> void:
	"""Release all pendulums from starting angle"""
	for pend in pendulums:
		pend["angle"] = release_angle
		pend["angular_velocity"] = 0.0
		pend["angular_acceleration"] = -float(pend["omega"]) * float(pend["omega"]) * release_angle

	is_released = true
	time_since_release = 0.0
	for trail in trail_points:
		trail.clear()
	_update_visualization()


## Public: set every bob off together from release_angle — the RELEASE button's action.
func release() -> void:
	_release_pendulums()


## Advance the rig by dt seconds. Frame-rate independent by construction; with
## relaunch_each_cycle the step is split exactly at the return to unison.
func step(dt: float) -> void:
	if not is_released or dt <= 0.0:
		return
	var remaining: float = dt
	var guard: int = 0
	while remaining > 0.0 and guard < 256:
		guard += 1
		if relaunch_each_cycle and _cycle > 0.0:
			var to_unison: float = maxf(_cycle - time_since_release, 0.0)
			if to_unison <= remaining:
				_advance(to_unison)
				remaining -= to_unison
				_relaunch()
				continue
		_advance(remaining)
		remaining = 0.0


## The decay the swing carries at clock time t, as k x (seconds of loss): the amplitude is
## release_angle * exp(-_decay_exponent(t)).
func _decay_exponent(t: float) -> float:
	if relaunch_each_cycle and _cycle > 0.0:
		return _decay_k * clampf(minf(t, _cycle - t), 0.0, _cycle * 0.5)
	return _decay_k * maxf(t, 0.0)


func _advance(h: float) -> void:
	if h <= 0.0:
		return
	var fade: float = exp(_decay_exponent(time_since_release) - _decay_exponent(time_since_release + h))
	for pend in pendulums:
		var w: float = float(pend["omega"])
		var c: float = cos(w * h)
		var s: float = sin(w * h)
		var a: float = float(pend["angle"])
		var v: float = float(pend["angular_velocity"])
		var a2: float = (a * c + (v / w) * s) * fade
		var v2: float = (v * c - a * w * s) * fade
		pend["angle"] = a2
		pend["angular_velocity"] = v2
		pend["angular_acceleration"] = -w * w * a2
	time_since_release += h


## At unison every bob is at the same extreme and momentarily still, and the envelope has
## already brought the swing back to release_angle, so this writes the state it already has
## (to rounding) and restarts the clock. A rig whose relaunch was switched on mid-run is the
## one case where it lifts the bobs visibly.
func _relaunch() -> void:
	for pend in pendulums:
		pend["angle"] = release_angle
		pend["angular_velocity"] = 0.0
		pend["angular_acceleration"] = -float(pend["omega"]) * float(pend["omega"]) * release_angle
	time_since_release = 0.0


func _update_visualization() -> void:
	"""Update visual position of pendulums"""
	var in_tree: bool = is_inside_tree()
	for i in range(mini(pendulums.size(), _containers.size())):
		var pend: Dictionary = pendulums[i]
		var container = _containers[i]
		if not is_instance_valid(container):
			continue

		var bob_offset: Vector3 = _bob_offset(float(pend["angle"]), float(pend["length"]))

		var bob = _bobs[i] if i < _bobs.size() else null
		if is_instance_valid(bob):
			bob.position = bob_offset
			if in_tree and trail_length > 0:
				# to_global, not global_position + offset: the offset is LOCAL, and a placement
				# turned 90 degrees would otherwise report a swing across the bar as one along it.
				var world_pos: Vector3 = container.to_global(bob_offset)
				trail_points[i].append(world_pos)
				if trail_points[i].size() > trail_length:
					trail_points[i].pop_front()

		# The rod lies along the bob offset: rotating local +Y about X by -θ gives
		# (0, cos θ, -sin θ), parallel to (0, -cos θ, sin θ).
		var rod = _rods[i] if i < _rods.size() else null
		if is_instance_valid(rod):
			rod.position = bob_offset * 0.5
			rod.rotation = Vector3(-float(pend["angle"]), 0.0, 0.0)


## The swing is ACROSS the bar (Z), never along it: the pivots are 0.3 m apart and the bobs
## travel further than that, so a swing along X passes neighbours through each other.
func _bob_offset(angle: float, length: float) -> Vector3:
	return Vector3(0.0, -cos(angle) * length, sin(angle) * length)


## Public: push the current state onto the meshes (a probe's readback path).
func sync_visuals() -> void:
	_update_visualization()


func get_bob_position(index: int) -> Vector3:
	"""Get world position of specific pendulum bob"""
	if index >= 0 and index < pendulums.size() and index < _containers.size():
		var pend: Dictionary = pendulums[index]
		var container = _containers[index]
		if is_instance_valid(container):
			var offset: Vector3 = _bob_offset(float(pend["angle"]), float(pend["length"]))
			if container.is_inside_tree():
				return container.to_global(offset)
			return container.position + offset
	return Vector3.ZERO


func get_wave_phase() -> float:
	"""Fraction of the cycle since release (0 to 1): 0 is unison, 0.5 the two interleaved rows"""
	if pendulums.size() == 0 or _cycle <= 0.0:
		return 0.0
	return fmod(time_since_release / _cycle, 1.0)


## Seconds from unison to unison, as built.
func get_cycle_time() -> float:
	return _cycle


func get_lengths() -> PackedFloat64Array:
	var out := PackedFloat64Array()
	for pend in pendulums:
		out.append(float(pend["length"]))
	return out


## Full swings each pendulum makes over one cycle: consecutive integers.
func get_swing_counts() -> PackedInt32Array:
	var out := PackedInt32Array()
	for pend in pendulums:
		out.append(int(pend["swings"]))
	return out


## Amplitude decay rate k (1/s): the swing keeps exp(-k t) of its height after t seconds.
func get_decay_rate() -> float:
	return _decay_k


func reset() -> void:
	"""Reset all pendulums to starting position"""
	is_released = false
	time_since_release = 0.0
	for pend in pendulums:
		pend["angle"] = 0.0
		pend["angular_velocity"] = 0.0
		pend["angular_acceleration"] = 0.0
	for trail in trail_points:
		trail.clear()
	_update_visualization()


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Reads exactly one key. An absent or unknown "armature" leaves the shipped value alone,
	# which keeps every existing placement on the legacy path. The museum may call this
	# before _ready: then it only stores the value and _build() uses it once.
	if config.has("armature"):
		var want: String = str(config["armature"]).strip_edges().to_lower()
		if ARMATURES.has(want) and want != armature:
			armature = want
			if _built:
				_build_armature()


# ── THE STAND: caption and RELEASE ───────────────────────────────────────────
# One slim post at the front-left, clear of the swing and outside the row as the capture
# camera (front-right) sees it: a TextScreen caption at reading height and a one-button
# rack panel under it at hand height. Both face +Z, the side the rig presents.

func _swing_reach() -> float:
	var ang: float = clampf(absf(release_angle), 0.0, PI * 0.5)
	var reach: float = 0.0
	for pend in pendulums:
		reach = maxf(reach, float(pend["length"]) * sin(ang))
	if pendulums.is_empty():
		reach = maxf(shortest_length, longest_length) * sin(ang)
	return reach + bob_radius


func _stand_position() -> Vector3:
	var half: float = float(maxi(num_pendulums, 1) - 1) * 0.5 * pendulum_spacing
	return Vector3(-(half + pendulum_spacing + 0.35), 0.0, _swing_reach() + 0.45)


func _build_stand() -> void:
	var at: Vector3 = _stand_position()

	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.20, 0.22, 0.27)
	post_mat.roughness = 0.5

	var post := MeshInstance3D.new()
	post.name = "StandPost"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.02
	cyl.height = CAPTION_Y
	post.mesh = cyl
	post.material_override = post_mat
	post.position = Vector3(at.x, CAPTION_Y * 0.5, at.z - 0.04)
	_own(post)

	var foot := MeshInstance3D.new()
	foot.name = "StandFoot"
	var foot_cyl := CylinderMesh.new()
	foot_cyl.top_radius = 0.15
	foot_cyl.bottom_radius = 0.17
	foot_cyl.height = 0.02
	foot.mesh = foot_cyl
	foot.material_override = post_mat
	foot.position = Vector3(at.x, 0.01, at.z - 0.04)
	_own(foot)

	var cap = TEXT_SCREEN_SCRIPT.new()
	cap.name = "Caption"
	cap.mode = 0                                  # SCREEN — a face on the post, no stand of its own
	cap.width_m = CAPTION_W
	cap.title = "Pendulum wave"
	cap.body = _caption_body()
	cap.position = Vector3(at.x, CAPTION_Y, at.z)
	_own(cap)
	_caption = cap

	if not Engine.is_editor_hint():
		_build_release_panel(at)


func _caption_body() -> String:
	var n: int = pendulums.size()
	var count_word: String = _number_word(n)
	var last: int = _first_swings + maxi(n - 1, 0)
	# Broken by hand, every line inside TextScreen's 52 columns at width 1.0 m, so the screen
	# never reflows one and splits the name of the work across two lines.
	return ("%s pendulums · %d to %d full swings per cycle\n"
		+ "unison, a travelling snake, apparent disorder,\n"
		+ "and unison again at %.1f s\n"
		+ "one pattern at %s rates,\n"
		+ "as in Steve Reich's Piano Phase (1967)\n"
		+ "press RELEASE to set them off together") % [count_word, _first_swings, last, _cycle, count_word]


func _number_word(n: int) -> String:
	var words: PackedStringArray = ["zero", "one", "two", "three", "four", "five", "six", "seven",
		"eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
		"sixteen", "seventeen", "eighteen", "nineteen", "twenty"]
	if n >= 0 and n < words.size():
		return words[n]
	return str(n)


## RELEASE, wired the way shannon_entropy_meter wires SORT · CONTRAST · DISCLOSE: a
## RackTemplates panel, and a LAMBDA on InteractableAreaButton.button_pressed — the signal
## carries the button, so a 0-arg method connected directly would be a dead button. VR
## hands press the area by touch; the desktop pointer presses it through
## interactable_area_button_pointer.gd.
func _build_release_panel(at: Vector3) -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl == null:
		return
	_panel = RackTpl.create_panel(" ", [
		[{"type": "button", "label": "RELEASE"}],
	])
	_panel.name = "ReleasePanel"
	# the panel's button areas are hand targets, not the rig's footprint
	_panel.set_meta("em_local_instrument", true)
	_panel.position = Vector3(at.x, PANEL_Y, at.z)
	_panel.scale = Vector3.ONE * PANEL_SCALE
	_own(_panel)
	var btn: Node = _panel.find_child("Btn_0", true, false)
	if btn == null:
		return
	var area: Node = btn.get_node_or_null("InteractableAreaButton")
	if area != null and area.has_signal("button_pressed"):
		area.button_pressed.connect(func(_b): release())


# ── ARMATURE ─────────────────────────────────────────────────────────────────
# One axis, four moments, shared word for word with facade_builder.gd. Everything below runs
# AFTER the array is built and lives inside one host node, so removing that single node
# restores the bare rig exactly. Nothing here reads or writes the pendulum dictionaries'
# motion, the periods or the integration — it only MEASURES the array that is already
# there, so the drawing can be true to the build rather than to a second copy of the formula.

const ARM_HOST := "Armature"
const ARM_CLEAR := 0.12         # how far the board and scaffold rows stand past the swing
const ARM_TOWER_LIFT := 0.70    # how far a gantry tower stands past the end of the bar
const ARM_HOIST_BACK := 0.12    # the hoist's chain line, behind the bar's centre line (bar is 0.05 deep)


func _build_armature() -> void:
	var old: Node = get_node_or_null(ARM_HOST)
	if old != null:
		remove_child(old)
		old.queue_free()
	if armature == "none" or not ARMATURES.has(armature):
		return                          # the legacy lineage builds nothing at all
	var host := Node3D.new()
	host.name = ARM_HOST
	add_child(host)

	var n: int = maxi(num_pendulums, 1)
	var half: float = float(n - 1) * 0.5 * pendulum_spacing
	var bar_w: float = float(n) * pendulum_spacing + pendulum_spacing
	match armature:
		"datum":
			_armature_datum(host, half, bar_w)
		"scaffold":
			_armature_scaffold(host, half, bar_w)
		"gantry":
			_armature_gantry(host, half, bar_w)
		_:
			pass


## DATUM — the drawing left on the rig. A pale board stands behind the swing carrying
## the pivot datum as one continuous line, a station tick under every pendulum, and the
## LENGTH LADDER: a short mark at each station drawn at that pendulum's rest height, risers
## joining mark to mark. The lengths follow consecutive swing counts, so the ladder is a
## smooth monotone stair — the calculation that makes the wave, drawn instead of erased.
func _armature_datum(host: Node3D, half: float, bar_w: float) -> void:
	var board: StandardMaterial3D = _arm_mat(Color(0.845, 0.832, 0.795), 0.92, 0.0)
	var ink: StandardMaterial3D = _arm_mat(Color(0.115, 0.120, 0.145), 0.85, 0.0)
	var faint: StandardMaterial3D = _arm_mat(Color(0.520, 0.520, 0.545), 0.90, 0.0)
	var rule: StandardMaterial3D = _arm_emissive(Color(0.90, 0.42, 0.10), 0.9)

	# Behind the swing, not inside it: the bobs now travel across the bar.
	var board_z: float = -(_swing_reach() + ARM_CLEAR)
	var line_z: float = board_z + 0.025

	var bh: float = base_height + 0.34
	_arm_box(host, Vector3(0, bh * 0.5, board_z), Vector3(bar_w + 0.36, bh, 0.024), board)

	# The pivot datum: one line the whole width, at exactly the height the pivots sit.
	_arm_box(host, Vector3(0, base_height, line_z), Vector3(bar_w + 0.30, 0.022, 0.012), ink)
	# The ground line, so the datum is a height ABOVE something and not a floating claim.
	_arm_box(host, Vector3(0, 0.012, line_z), Vector3(bar_w + 0.30, 0.016, 0.012), faint)

	# Station ticks: one vertical rule per pendulum, dropped from the datum to its own bob.
	# Read off the built array so the drawing cannot disagree with the rig.
	var prev_y: float = -1.0
	var prev_x: float = 0.0
	for i in range(pendulums.size()):
		var pend: Dictionary = pendulums[i]
		var pivot: Vector3 = pend["pivot_position"]
		var px: float = pivot.x
		var rest_y: float = base_height - float(pend["length"])
		var drop: float = maxf(base_height - rest_y, 0.02)
		_arm_box(host, Vector3(px, rest_y + drop * 0.5, line_z),
			Vector3(0.008, drop, 0.010), faint)
		# The rest-height mark for this station.
		_arm_box(host, Vector3(px, rest_y, line_z + 0.004),
			Vector3(pendulum_spacing * 0.78, 0.016, 0.012), rule)
		# The riser joining this mark to the previous one — the stair of the sequence.
		if prev_y >= 0.0:
			var mid_x: float = (px + prev_x) * 0.5
			var span: float = absf(rest_y - prev_y)
			if span > 0.001:
				_arm_box(host, Vector3(mid_x, (rest_y + prev_y) * 0.5, line_z + 0.004),
					Vector3(0.010, span, 0.012), rule)
		prev_y = rest_y
		prev_x = px

	# Two witness marks squaring the board to the bar — the setting-out's own corners.
	for sx in [-1.0, 1.0]:
		var sf: float = float(sx)
		_arm_box(host, Vector3(sf * (half + pendulum_spacing), base_height, line_z + 0.004),
			Vector3(0.020, 0.16, 0.012), ink)


## SCAFFOLD — the working platform still up. Standards every metre and a half in two rows
## front and back of the swing, two lifts of ledgers, transoms tying the rows, a board
## deck running the whole front at waist height and a toe board along its outer edge. The rig
## caught mid-erection, the bobs swinging over somebody's boards.
func _armature_scaffold(host: Node3D, half: float, _bar_w: float) -> void:
	var tube: StandardMaterial3D = _arm_mat(Color(0.470, 0.485, 0.510), 0.42, 0.70)
	var plank: StandardMaterial3D = _arm_mat(Color(0.560, 0.450, 0.290), 0.88, 0.0)
	var band: StandardMaterial3D = _arm_mat(Color(0.880, 0.560, 0.090), 0.70, 0.10)

	# The two rows stand past the swing across the bar, measured from the built lengths.
	var deck_z: float = _swing_reach() + ARM_CLEAR
	var top: float = base_height + 0.60
	var reach: float = half + pendulum_spacing
	var bays: int = maxi(int(round((reach * 2.0) / 1.5)), 2)
	var deck_y: float = maxf(base_height - longest_length - 0.42, 0.35)

	# Standards, two rows clear of the swing in Z.
	for b in range(bays + 1):
		var sx: float = -reach + (reach * 2.0) * (float(b) / float(bays))
		for sz in [-deck_z, deck_z]:
			var zf: float = float(sz)
			_arm_box(host, Vector3(sx, top * 0.5, zf), Vector3(0.048, top, 0.048), tube)
			_arm_box(host, Vector3(sx, 0.012, zf), Vector3(0.16, 0.024, 0.16), tube)
		# Transom tying the two rows at deck level.
		_arm_box(host, Vector3(sx, deck_y + 0.06, 0), Vector3(0.040, 0.040, deck_z * 2.0), tube)

	# Ledgers: three lifts, both rows, the whole run.
	for lift in [deck_y + 0.06, base_height - 0.30, top - 0.14]:
		var ly: float = float(lift)
		for sz2 in [-deck_z, deck_z]:
			var zg: float = float(sz2)
			_arm_box(host, Vector3(0, ly, zg), Vector3(reach * 2.0 + 0.10, 0.038, 0.038), tube)

	# The board deck: four planks laid across the front bay, plus the toe board.
	for k in range(4):
		var pz: float = deck_z - 0.06 - float(k) * 0.115
		_arm_box(host, Vector3(0, deck_y + 0.12, pz),
			Vector3(reach * 2.0 - 0.02, 0.030, 0.108), plank)
	_arm_box(host, Vector3(0, deck_y + 0.20, deck_z - 0.005),
		Vector3(reach * 2.0 - 0.02, 0.130, 0.026), plank)
	# Guard band along the top ledger — the only warm colour on the frame.
	_arm_box(host, Vector3(0, top - 0.14, deck_z + 0.03),
		Vector3(reach * 2.0 + 0.10, 0.050, 0.014), band)


## GANTRY — the lifting frame. Two braced towers stand past the ends of the bar, a lattice
## head beam runs between them over the array, and a hoist block hangs on a chain between the
## two middle stations, just behind the bar. Not the array that resulted: the machinery that
## PUT fifteen different lengths where they are.
func _armature_gantry(host: Node3D, half: float, _bar_w: float) -> void:
	var steel: StandardMaterial3D = _arm_mat(Color(0.400, 0.415, 0.450), 0.40, 0.76)
	var paint: StandardMaterial3D = _arm_mat(Color(0.880, 0.560, 0.090), 0.66, 0.15)
	var dark: StandardMaterial3D = _arm_mat(Color(0.130, 0.135, 0.155), 0.75, 0.30)

	var tx: float = half + ARM_TOWER_LIFT
	var top: float = base_height + 0.78
	var leg: float = 0.30                      # half the tower's footprint

	for sx in [-1.0, 1.0]:
		var sf: float = float(sx)
		var cx: float = sf * tx
		# Four legs and a base plate.
		for ox in [-leg, leg]:
			for oz in [-leg, leg]:
				_arm_box(host, Vector3(cx + float(ox), top * 0.5, float(oz)),
					Vector3(0.055, top, 0.055), steel)
		_arm_box(host, Vector3(cx, 0.020, 0), Vector3(leg * 2.4, 0.040, leg * 2.4), dark)
		# Cross bracing on the face that reads from the sweep's camera (yaw 0.62 puts the
		# +Z face toward it): five lifts of diagonals, each long enough to actually reach
		# corner to corner of its bay (bay 0.60 wide x top*0.18 tall, so leg*2.8 at 45°).
		for k in range(5):
			var y0: float = top * (0.08 + 0.18 * float(k))
			var diag: MeshInstance3D = _arm_make_box(
				Vector3(cx, y0 + top * 0.09, leg), Vector3(0.034, leg * 2.80, 0.034), steel)
			diag.rotation.z = PI * 0.25 if (k % 2) == 0 else -PI * 0.25
			host.add_child(diag)
			_arm_box(host, Vector3(cx, y0, 0), Vector3(leg * 2.0, 0.034, 0.034), steel)

	# Head beam: two chords with verticals between them, spanning tower to tower.
	var span: float = tx * 2.0 + leg * 2.0
	for cy in [top - 0.10, top - 0.42]:
		_arm_box(host, Vector3(0, float(cy), 0), Vector3(span, 0.070, 0.070), paint)
	var posts: int = maxi(int(span / 0.55), 4)
	for p in range(posts + 1):
		var ux: float = -span * 0.5 + span * (float(p) / float(posts))
		_arm_box(host, Vector3(ux, top - 0.26, 0), Vector3(0.036, 0.320, 0.036), steel)

	# The hoist: a trolley on the lower chord, an arm, a chain, a block and a hook. Before the
	# 2026-09-16 review it hung at x = 0, z = 0: two chain links ran through the pivot bar and
	# the block and hook sat inside the centre pendulum's rod. It now hangs in the GAP between
	# the two middle stations (no rod has that x) and ARM_HOIST_BACK behind the bar's centre
	# line (the chain passes the bar's back face instead of its middle). Every piece is named
	# Hoist* so the probe can test that clearance rather than trust this comment.
	var n_st: int = maxi(num_pendulums, 1)
	var gap_x: float = pendulum_spacing * 0.5 if (n_st % 2) == 1 else 0.0
	var hz: float = -ARM_HOIST_BACK
	# the block and hook stay narrower than the gap between two rods, whatever the spacing
	var free_w: float = maxf(pendulum_spacing - 2.0 * rod_thickness - 0.06, 0.03)
	var block_w: float = minf(0.150, free_w)
	var hook_w: float = minf(0.048, free_w)
	_arm_named(host, "HoistTrolley", Vector3(gap_x, top - 0.50, 0), Vector3(0.230, 0.110, 0.190), paint)
	_arm_named(host, "HoistArm", Vector3(gap_x, top - 0.565, hz * 0.5),
		Vector3(0.040, 0.030, ARM_HOIST_BACK + 0.040), paint)
	var links: int = 6
	for l in range(links):
		var ly: float = top - 0.58 - float(l) * 0.075
		var link: MeshInstance3D = _arm_named(host, "HoistLink_%d" % l, Vector3(gap_x, ly, hz),
			Vector3(0.030, 0.062, 0.030), dark)
		link.rotation.y = PI * 0.25 if (l % 2) == 0 else 0.0
	_arm_named(host, "HoistBlock", Vector3(gap_x, top - 1.06, hz), Vector3(block_w, 0.150, 0.110), dark)
	_arm_named(host, "HoistHook", Vector3(gap_x, top - 1.18, hz), Vector3(hook_w, 0.130, 0.048), steel)


# ── armature helpers ─────────────────────────────────────────────────────────

func _arm_make_box(centre: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = centre
	return mi


func _arm_box(host: Node3D, centre: Vector3, size: Vector3, mat: Material) -> void:
	host.add_child(_arm_make_box(centre, size, mat))


func _arm_named(host: Node3D, node_name: String, centre: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = _arm_make_box(centre, size, mat)
	mi.name = node_name
	host.add_child(mi)
	return mi


func _arm_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _arm_emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
