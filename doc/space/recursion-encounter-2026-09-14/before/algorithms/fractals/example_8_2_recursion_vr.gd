# ===========================================================================
# NOC Example 8.2: Recursion (Variant)
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.2: Recursion (Nested Squares)
## Recursive pattern of squares within squares
## Chapter 08: Fractals
##
## Each iteration has a distinct color from a predefined palette.
## A frame surrounds the entire pattern.

# @identity
# essence: square(center, size, d) = box(size) + square(center, size * 0.5, d-1)
# desire: To be stared into — concentric squares receding in Z, each layer a different color, pulling the eye inward
# critical_parameter: size_reduction (0.5) — the ratio between parent and child determines whether the nesting feels dense or sparse
# triggers: depth increase → deeper nesting; z-offset per layer prevents z-fighting and creates parallax depth
# emerges: A tunnel effect from flat geometry — depth perception from color gradient and z-stacking alone
# needs: VR depth control [missing], animation toggle [missing]
# relationships: Simplest 2D recursion before Koch and Sierpinski; sibling to example_8_1 (concentric circles)
# truth: A square inside a square is not decoration — it is the first evidence that a function can call itself.

# ─────────────────────────────────────────────────────────────────────
#  STAGE-2 DNA — hand promotion 2026-08-05. The runner refused this token
#  for NO TURNABLE KNOBS: five exports, every one a count, a ratio, a size
#  or a flag, and apply_grid_config's whole body was `pass`, so not one of
#  them was reachable from a map token.
#
#  depth      — how many times the rule is allowed to call itself. The word
#               is example_8_3_recursion_circles_vr's, one file along in the
#               same NOC chapter and the same algorithm with tori instead of
#               boxes, and through it the L-system family's (lsystem_editor,
#               room_grammar, space_filling_curve_gallery). DELIBERATELY NOT
#               `tick`: cantor_set, sierpinski_pyramid, menger_sponge,
#               cube_subdivision and zeno_staircase share
#               once|coarse|fine|dense|limit for a rule reapplied to a SET,
#               and their top rung gestures at an idealised limit object.
#               THE BRANCHING FACTOR HERE IS ONE. _draw_recursive_pattern
#               makes exactly one recursive call, so the population at every
#               level is a single square and a "generation" is a term, not a
#               set. 8.3 refused the word for its own reason (4-fold, 5,461
#               tori at `limit`); this file refuses it for the opposite one,
#               and both refusals leave the two halves of one lesson
#               answering to the same word.
#
#  recession  — what shape the descent takes. folding_past's word and its
#               four values, and it is already in this file's own @identity:
#               "concentric squares receding in Z". The nesting is a CLAIM
#               about a self-call — that the child lives inside the parent —
#               and this recursion is a TAIL call, which is to say a loop:
#               nothing is contained, each term simply follows the last.
#               `abreast` stages that counterfactual, `strata` the third
#               figure (deposition, each term sitting on the one before),
#               `collapsed` drives the nest to its own limit inside an
#               unchanged frame.
#
#  THE LADDER WAS MEASURED, NOT ASSUMED. The recursion stops on
#  `d <= 0 or size < 0.01`, so at the shipped initial_size 1.0 and
#  size_reduction 0.5 the terms are 1.0, 0.5, 0.25, 0.125, 0.0625, 0.03125,
#  0.015625 and the eighth, 0.0078125, is culled. SEVEN rungs build and an
#  eighth cannot, which is why the declared ladder stops at 7 — the
#  example_8_4 fault (a rung that exists in the enum and cannot be drawn)
#  found before declaring rather than after. 6 is the shipped number, so the
#  axis runs both ways.
# ─────────────────────────────────────────────────────────────────────

const TERM_MIN_SIZE := 0.01
const RECESSIONS := ["nested", "collapsed", "abreast", "strata"]

@export_range(1, 7) var depth: int = 6
@export_enum("nested", "collapsed", "abreast", "strata") var recession: String = "nested"
@export var size_reduction: float = 0.5
@export var initial_size: float = 1.0
@export var show_frame: bool = true
@export var frame_thickness: float = 0.02

# Color palette for each iteration depth (0 = outermost)
var iteration_colors: Array[Color] = [
	Color(0.9, 0.2, 0.3, 0.9),   # Iteration 1: Red
	Color(0.95, 0.5, 0.1, 0.85), # Iteration 2: Orange
	Color(0.95, 0.85, 0.2, 0.8), # Iteration 3: Yellow
	Color(0.3, 0.85, 0.4, 0.75), # Iteration 4: Green
	Color(0.2, 0.6, 0.95, 0.7),  # Iteration 5: Blue
	Color(0.7, 0.3, 0.9, 0.65),  # Iteration 6: Purple
]

var _sim_root: Node3D
var _mesh_instances: Array[MeshInstance3D] = []
var _built: bool = false

func _ready() -> void:
	_read_dna()
	_build()
	set_process(false)
	_built = true


func _build() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

	# Draw the frame first (behind everything)
	if show_frame:
		var b: Vector2 = _frame_bounds()
		_create_frame(Vector3.ZERO, b.x, b.y)

	# Draw recursive pattern
	_draw_recursive_pattern(Vector3.ZERO, initial_size, depth)


## The sizes the recursion will actually lay down, in order, by the same two
## stop conditions _draw_recursive_pattern opens with. Asked ahead of the walk
## so a layout can know the run before it starts placing terms — the recursion
## itself is untouched and still does the drawing.
func _terms() -> Array[float]:
	var out: Array[float] = []
	var size: float = initial_size
	var d: int = depth
	while d > 0 and size >= TERM_MIN_SIZE:
		out.append(size)
		size = size * size_reduction
		d -= 1
	return out


## What the frame encloses. `nested` and `collapsed` hand back the shipped
## initial_size square unchanged — a square frame of the artifact's own extent,
## which is what this file has always drawn. The two laid-out arrangements are
## longer than they are tall (or the reverse), and a frame that stayed square
## would sit across the middle of its own picture.
func _frame_bounds() -> Vector2:
	var sizes: Array[float] = _terms()
	if sizes.is_empty():
		return Vector2(initial_size, initial_size)
	var run: float = 0.0
	for s in sizes:
		run += s
	if recession == "abreast":
		return Vector2(run, sizes[0])
	if recession == "strata":
		return Vector2(sizes[0], run)
	return Vector2(initial_size, initial_size)


## Where a term sits relative to the one that called it.
##
## `nested` and `collapsed` return ZERO, which is the centre every square has
## been drawn at since this file was written — containment, the child inside the
## parent. `abreast` walks the terms along X with their bottom edges aligned, so
## the halving reads as a descending row and nothing is inside anything.
## `strata` stacks them up Y, each term sitting on the one before it, oldest at
## the bottom. The run is the sum of the sizes the rule itself produced, so no
## spacing constant is invented anywhere in here.
func _seat(level: int) -> Vector3:
	if recession == "nested" or recession == "collapsed":
		return Vector3.ZERO
	var sizes: Array[float] = _terms()
	if level < 0 or level >= sizes.size():
		return Vector3.ZERO
	var run: float = 0.0
	for s in sizes:
		run += s
	var walked: float = 0.0
	for i in range(level):
		walked += sizes[i]
	var along: float = walked + sizes[level] * 0.5 - run * 0.5
	if recession == "abreast":
		return Vector3(along, (sizes[level] - sizes[0]) * 0.5, 0.0)
	return Vector3(0.0, along, 0.0)


## The size a term is DRAWN at, which is its own size everywhere except
## `collapsed`, where every term is drawn at the innermost one — the nest driven
## to its limit, all of it on the last term, inside a frame that has not moved.
func _drawn_size(size: float) -> float:
	if recession != "collapsed":
		return size
	var sizes: Array[float] = _terms()
	if sizes.is_empty():
		return size
	return sizes[sizes.size() - 1]


func _create_frame(center: Vector3, width: float, height: float) -> void:
	# Create 4 bars forming a frame around the pattern
	var half_w: float = width * 0.5
	var half_h: float = height * 0.5
	var bar_w: float = width + frame_thickness * 2
	var bar_h: float = height + frame_thickness * 2

	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.2, 0.2, 0.25, 1.0)
	frame_material.metallic = 0.3
	frame_material.roughness = 0.7

	# Top bar
	_create_frame_bar(center + Vector3(0, half_h + frame_thickness * 0.5, 0),
					  Vector3(bar_w, frame_thickness, frame_thickness), frame_material)
	# Bottom bar
	_create_frame_bar(center + Vector3(0, -half_h - frame_thickness * 0.5, 0),
					  Vector3(bar_w, frame_thickness, frame_thickness), frame_material)
	# Left bar
	_create_frame_bar(center + Vector3(-half_w - frame_thickness * 0.5, 0, 0),
					  Vector3(frame_thickness, bar_h, frame_thickness), frame_material)
	# Right bar
	_create_frame_bar(center + Vector3(half_w + frame_thickness * 0.5, 0, 0),
					  Vector3(frame_thickness, bar_h, frame_thickness), frame_material)


func _create_frame_bar(pos: Vector3, bar_size: Vector3, mat: StandardMaterial3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = bar_size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = mat
	_sim_root.add_child(mesh_instance)


func _draw_recursive_pattern(center: Vector3, size: float, d: int) -> void:
	if d <= 0 or size < TERM_MIN_SIZE:
		return

	# Draw square at this level. At recession=nested _seat is ZERO and _drawn_size
	# hands the size straight back, so this is the shipped call verbatim.
	_create_square(center + _seat(depth - d), _drawn_size(size), d)

	# Recurse with smaller squares
	var new_size: float = size * size_reduction
	_draw_recursive_pattern(center, new_size, d - 1)


func _create_square(center: Vector3, size: float, d: int) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, size, 0.005)
	mesh_instance.mesh = box
	# Offset each layer slightly in Z to prevent z-fighting
	mesh_instance.position = center + Vector3(0, 0, (depth - d) * 0.003)

	var material := StandardMaterial3D.new()

	# Get color for this iteration (d goes from depth down to 1)
	var iteration_index := depth - d
	var color: Color
	if iteration_index < iteration_colors.size():
		color = iteration_colors[iteration_index]
	else:
		# Fallback: cycle through colors
		color = iteration_colors[iteration_index % iteration_colors.size()]

	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.5
	material.emission_energy_multiplier = 0.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	_sim_root.add_child(mesh_instance)
	_mesh_instances.append(mesh_instance)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Read the two axes off the metadata the grid stamps on the artifact ROOT, which
## happens before add_child and therefore before a single square exists. An
## unknown word, or a number outside the range, keeps the value already held.
func _read_dna() -> void:
	if has_meta("config_depth"):
		_take_depth(get_meta("config_depth"))
	elif has_meta("config_max_depth"):
		# `max_depth` was this export's name until the promotion; kept as an alias
		# so a token written against the old name is not silently thrown away.
		_take_depth(get_meta("config_max_depth"))
	if has_meta("config_recession"):
		var r: String = str(get_meta("config_recession")).strip_edges().to_lower()
		if RECESSIONS.has(r):
			recession = r


## int(str(...)) because a map token's value arrives as a String, and assigning a
## String to a typed int property is rejected without a word of complaint.
func _take_depth(raw) -> void:
	depth = clampi(int(str(raw)), 1, 7)


## Tear the drawing down and lay it out again. remove_child is immediate, so the
## old root leaves the tree before the new one enters and no frame shows two.
func _rebuild() -> void:
	if _sim_root != null and is_instance_valid(_sim_root):
		remove_child(_sim_root)
		_sim_root.queue_free()
	_sim_root = null
	_mesh_instances.clear()
	_build()


## Reads the two declared axes, and the three knobs that were exported but
## unreachable because this function's whole body used to be `pass`.
##
## GUARDED TWICE ON PURPOSE. A value is taken only when it validates AND differs,
## and the rebuild fires only after the first build has happened. Every existing
## placement carries the bare token with no config keys at all — the grid does not
## even call this method when a token has no config — so none of them can reach a
## rebuild and all of them draw exactly what they drew before.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	var changed: bool = false

	if config.has("depth") or config.has("max_depth"):
		var raw: Variant = config["depth"] if config.has("depth") else config["max_depth"]
		var d: int = clampi(int(str(raw)), 1, 7)
		if d != depth:
			depth = d
			changed = true

	if config.has("recession"):
		var r: String = str(config["recession"]).strip_edges().to_lower()
		if RECESSIONS.has(r) and r != recession:
			recession = r
			changed = true

	if config.has("size_reduction"):
		var sr: float = float(config["size_reduction"])
		if sr > 0.0 and not is_equal_approx(sr, size_reduction):
			size_reduction = sr
			changed = true

	if config.has("initial_size"):
		var isz: float = float(config["initial_size"])
		if isz > 0.0 and not is_equal_approx(isz, initial_size):
			initial_size = isz
			changed = true

	if config.has("show_frame"):
		# bool("false") is TRUE in GDScript — every non-empty string is — so the
		# word is read rather than cast.
		var sv: String = str(config["show_frame"]).strip_edges().to_lower()
		var sf: bool = not (sv == "false" or sv == "0" or sv == "no")
		if sf != show_frame:
			show_frame = sf
			changed = true

	if not changed:
		return
	# Before the first build there is nothing to tear down — _ready() picks the new
	# values up when it runs.
	if not _built:
		return
	_rebuild()
