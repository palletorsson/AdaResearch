# Ethical Design Clipboard — ethics as architecture, not post-processing
#
# A clipboard mounted on a pillar. On its surface, a list of design moves with toggles:
#   - "include affected parties in the design loop"
#   - "make exclusion visible in the data"
#   - "treat the room's shape as a moral object"
# Toggling these moves shifts the room around the clipboard: walls rearrange, lighting
# softens or hardens, a previously hidden door appears or disappears.
#
# The point: ethical design isn't a checkbox after the fact. The toggles ARE the room.
#
# @identity: First map after Gödel where ethics becomes architecture.
# @qfep_term: Edge — what becomes possible once you stop demanding completeness.

extends Node3D
class_name EthicalDesignClipboard

@export_category("Clipboard Settings")
@export var clipboard_color: Color = Color(0.95, 0.93, 0.85, 1.0)
@export var stand_color: Color = Color(0.4, 0.45, 0.5, 1.0)
@export var checkmark_color: Color = Color(0.45, 0.85, 0.55, 1.0)
@export var stand_height: float = 1.0

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — the adoption axis
# ═══════════════════════════════════════════════════════════════════
#
# The header above has always promised that the three principles move the room.
# The code has always built a stand, a board and three tick lines, and nothing else;
# apply_grid_config() was an empty `pass`. An artifact arguing "ethics is not a
# checkbox after the fact" shipped as three checkboxes, which quietly proves the
# opposite. `adoption` is the distance those three principles have travelled from a
# written list to the room itself, and it is the one thing about this object worth
# varying because it is the artifact's entire claim.
#
#   paper    the list stays a list — a clipboard, chest high, read by one person
#   posted   the same list, four times the board area and raised overhead: a public
#            notice. Still only writing, but writing that addresses a room
#   built    each line has grown its physical counterpart on the floor around the
#            stand. The doorway, the marked-out exclusions, the circle of seats
#   dropped  the stand is empty and the board is face down at its foot. The
#            principles were put down. Nothing was built
#
# Every value is a change in MASS and PRESENCE, readable from across the room and
# from any angle — a still holds all four apart. Nothing here varies over time.
## How far the three written principles have travelled into the room: a clipboard,
## a raised public notice, three built floor members, or a board put face down.
@export_enum("paper", "posted", "built", "dropped") var adoption: String = "paper"

const ADOPTIONS: PackedStringArray = ["paper", "posted", "built", "dropped"]

## Posted: the board becomes a notice. 1.3 x 1.7 m is ~4.6x the 0.6 x 0.8 clipboard
## area, raised to eye-plus and laid back to 8 degrees so it reads from a distance
## instead of from arm's length. A polite 20% enlargement would have been invisible.
const POSTED_BOARD: Vector2 = Vector2(1.3, 1.7)
const POSTED_CENTRE_Y: float = 2.0
const POSTED_TILT_DEG: float = 8.0
const POSTED_FONT: int = 48
const POSTED_LINE_STEP: float = 0.38

## Built: the three lines, one to one, as three floor members.
##   line 1 "include affected parties"  -> an open doorframe you can walk through
##   line 2 "make exclusion visible"    -> a marked plate with the excluded counted out
##   line 3 "the room's shape is moral" -> a circle of seats, all facing each other
const DOOR_WIDTH: float = 1.0
const DOOR_HEIGHT: float = 1.4
const DOOR_MEMBER: float = 0.08
const DOOR_Z: float = -1.1
const PLATE_SIZE: float = 1.0
const PLATE_X: float = 1.1
const PEG_COUNT: int = 10
const PEG_HEIGHT: float = 0.25
const SEAT_COUNT: int = 6
const SEAT_SIZE: float = 0.35
const SEAT_RADIUS: float = 1.1
## The ring is phase-shifted 15 degrees so no seat is born inside the doorframe at
## z -1.1 or on top of the plate at x +1.1. Six seats at 1.1 m either way — the
## offset only stops the three members from interpenetrating.
const SEAT_PHASE_DEG: float = 15.0

## Dropped: how far from the stand's foot the board came to rest, face down.
const DROPPED_OFFSET_Z: float = 0.35


## Set once the geometry exists, so a config applied BEFORE _ready() only sets the
## axis and lets _ready() do the single build — never two overlapping clipboards.
var _built: bool = false

## Every node THIS script put under the artifact. A rebuild frees these and only
## these: label plates, packaging and tags added by the grid system are other
## people's children and must survive.
var _owned: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true


## Parent a node and record it as ours, so _rebuild_now() can take it back out.
func _add_owned(node: Node) -> void:
	add_child(node)
	_owned.append(node)


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	match adoption:
		"posted":
			_build_stand()
			_build_posted_board()
			_build_posted_text_lines()
		"built":
			# The board is untouched — `built` adds the room, it does not replace
			# the list. The written line and its floor member must be readable in
			# the same glance or the one-to-one claim is unverifiable.
			_build_stand()
			_build_clipboard()
			_build_text_lines()
			_build_doorframe()
			_build_exclusion_plate()
			_build_seat_ring()
		"dropped":
			# No board on the stand, no clip, no lines. Only the empty support and
			# the thing that used to hang on it, lying face down on the floor.
			_build_stand()
			_build_fallen_board()
		_:
			# "paper" — the legacy look, unchanged, for every placement that does
			# not ask for anything.
			_build_stand()
			_build_clipboard()
			_build_text_lines()


## Swap the geometry in place, synchronously. remove_child() takes the old nodes out
## of the tree in this same frame, so there is never a moment with two clipboards,
## and the fresh build exists before this call returns — before the grid system's
## label framing and auto-grounding run on us.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_build_all()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	var before_adoption: String = adoption
	if config_data.has("adoption"):
		adoption = _pick_axis(str(config_data["adoption"]), ADOPTIONS, adoption)

	# On the normal grid path this runs BEFORE _ready(): nothing is in the tree and
	# nothing is built, so setting the axis is the whole job — _ready() will build
	# once, with the value just resolved.
	if not _built:
		return

	# Nothing geometric changed. This is curation_station's {"emissive": false} and
	# every other placement that carries no axis: it must come out of here with the
	# exact nodes _ready() built and the label framing already applied to them.
	# A config that changes nothing says nothing.
	if adoption == before_adoption:
		return

	_rebuild_now()
	print("[EthicalDesignClipboard] Config applied — adoption=%s" % [adoption])


## Accept an axis value only if it names something this artifact actually builds.
## A typo in a map token has to land on the legacy clipboard, never half-apply —
## a half-recognised value would strand a shipped placement with no board at all.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


# ═══════════════════════════════════════════════════════════════════
# PAPER — the legacy build, byte-for-byte
# ═══════════════════════════════════════════════════════════════════

func _build_stand() -> void:
	var stand := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.1
	cyl.height = stand_height
	stand.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = stand_color
	mat.metallic = 0.6
	mat.roughness = 0.4
	stand.material_override = mat
	stand.position.y = stand_height * 0.5
	_add_owned(stand)


func _build_clipboard() -> void:
	var board := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.8, 0.03)
	board.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = clipboard_color
	mat.roughness = 0.7
	mat.metallic = 0.0
	board.material_override = mat
	board.position = Vector3(0, stand_height + 0.4, 0)
	board.rotation.x = -PI * 0.18  # slight forward tilt
	_add_owned(board)
	# Clip at the top.
	var clip := MeshInstance3D.new()
	var clip_box := BoxMesh.new()
	clip_box.size = Vector3(0.4, 0.08, 0.06)
	clip.mesh = clip_box
	var clip_mat := StandardMaterial3D.new()
	clip_mat.albedo_color = stand_color
	clip_mat.metallic = 0.7
	clip.material_override = clip_mat
	clip.position = Vector3(0, stand_height + 0.78, 0.04)
	_add_owned(clip)


func _build_text_lines() -> void:
	var lines = [
		"include affected parties",
		"make exclusion visible",
		"the room's shape is moral",
	]
	for i in lines.size():
		var label := Label3D.new()
		label.text = "✓  " + lines[i]
		label.font_size = 20
		label.outline_size = 5
		label.modulate = Color(0.2, 0.2, 0.25, 1.0)
		label.modulate.r = 0.2; label.modulate.g = 0.2; label.modulate.b = 0.25
		label.position = Vector3(0, stand_height + 0.62 - float(i) * 0.16, 0.04)
		label.rotation.x = -PI * 0.18
		_add_owned(label)
	var title := Label3D.new()
	title.text = "Ethical Design"
	title.font_size = 28
	title.outline_size = 6
	title.modulate = checkmark_color
	title.position = Vector3(0, stand_height + 0.95, 0.0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_add_owned(title)


# ═══════════════════════════════════════════════════════════════════
# POSTED — the same words, addressed to a room
# ═══════════════════════════════════════════════════════════════════

func _build_posted_board() -> void:
	var tilt: float = -deg_to_rad(POSTED_TILT_DEG)
	var board := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(POSTED_BOARD.x, POSTED_BOARD.y, 0.04)
	board.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = clipboard_color
	mat.roughness = 0.7
	mat.metallic = 0.0
	board.material_override = mat
	board.position = Vector3(0, POSTED_CENTRE_Y, 0)
	board.rotation.x = tilt
	_add_owned(board)
	# The clip grows with the board — a notice board's top rail.
	var clip := MeshInstance3D.new()
	var clip_box := BoxMesh.new()
	clip_box.size = Vector3(POSTED_BOARD.x * 0.68, 0.14, 0.08)
	clip.mesh = clip_box
	var clip_mat := StandardMaterial3D.new()
	clip_mat.albedo_color = stand_color
	clip_mat.metallic = 0.7
	clip.material_override = clip_mat
	clip.position = Vector3(0, POSTED_CENTRE_Y + POSTED_BOARD.y * 0.5 - 0.02, 0.05)
	clip.rotation.x = tilt
	_add_owned(clip)


func _build_posted_text_lines() -> void:
	var tilt: float = -deg_to_rad(POSTED_TILT_DEG)
	var lines = [
		"include affected parties",
		"make exclusion visible",
		"the room's shape is moral",
	]
	# The whole notice lives INSIDE the board — headline and all — so the assembly
	# tops out at 2.85 m and clears low ceilings that a floating title would not.
	var top_y: float = POSTED_CENTRE_Y + 0.30
	for i in lines.size():
		var label := Label3D.new()
		label.text = "✓  " + lines[i]
		label.font_size = POSTED_FONT
		label.outline_size = 10
		label.modulate = Color(0.2, 0.2, 0.25, 1.0)
		label.position = Vector3(0, top_y - float(i) * POSTED_LINE_STEP, 0.06)
		label.rotation.x = tilt
		_add_owned(label)
	var title := Label3D.new()
	title.text = "Ethical Design"
	title.font_size = 64
	title.outline_size = 14
	title.modulate = checkmark_color
	title.position = Vector3(0, POSTED_CENTRE_Y + 0.62, 0.06)
	title.rotation.x = tilt
	_add_owned(title)


# ═══════════════════════════════════════════════════════════════════
# BUILT — one floor member per written line
# ═══════════════════════════════════════════════════════════════════

## "include affected parties" — an open doorframe, no leaf, nothing to unlock.
## The way in is the argument.
func _build_doorframe() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = stand_color
	mat.metallic = 0.35
	mat.roughness = 0.6
	var half: float = DOOR_WIDTH * 0.5
	for side in 2:
		var post := MeshInstance3D.new()
		var post_box := BoxMesh.new()
		post_box.size = Vector3(DOOR_MEMBER, DOOR_HEIGHT, DOOR_MEMBER)
		post.mesh = post_box
		post.material_override = mat
		var x: float = -half if side == 0 else half
		post.position = Vector3(x, DOOR_HEIGHT * 0.5, DOOR_Z)
		_add_owned(post)
	var lintel := MeshInstance3D.new()
	var lintel_box := BoxMesh.new()
	lintel_box.size = Vector3(DOOR_WIDTH + DOOR_MEMBER, DOOR_MEMBER, DOOR_MEMBER)
	lintel.mesh = lintel_box
	lintel.material_override = mat
	lintel.position = Vector3(0, DOOR_HEIGHT - DOOR_MEMBER * 0.5, DOOR_Z)
	_add_owned(lintel)


## "make exclusion visible" — a plate of ground with the ones left out standing up
## on it in red, countable from across the room. Ten of them, not a percentage.
func _build_exclusion_plate() -> void:
	var plate := MeshInstance3D.new()
	var plate_box := BoxMesh.new()
	plate_box.size = Vector3(PLATE_SIZE, 0.06, PLATE_SIZE)
	plate.mesh = plate_box
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.22, 0.23, 0.27, 1.0)
	plate_mat.roughness = 0.85
	plate.material_override = plate_mat
	plate.position = Vector3(PLATE_X, 0.03, 0)
	_add_owned(plate)

	var peg_mat := StandardMaterial3D.new()
	peg_mat.albedo_color = Color(0.85, 0.18, 0.2, 1.0)
	peg_mat.emission_enabled = true
	peg_mat.emission = Color(0.6, 0.06, 0.08, 1.0)
	peg_mat.emission_energy_multiplier = 0.6
	peg_mat.roughness = 0.5
	var cols: int = 5
	var step: float = PLATE_SIZE / float(cols + 1)
	for i in PEG_COUNT:
		var col: int = i % cols
		var row: int = int(float(i) / float(cols))
		var peg := MeshInstance3D.new()
		var peg_cyl := CylinderMesh.new()
		peg_cyl.top_radius = 0.035
		peg_cyl.bottom_radius = 0.035
		peg_cyl.height = PEG_HEIGHT
		peg.mesh = peg_cyl
		peg.material_override = peg_mat
		var px: float = PLATE_X - PLATE_SIZE * 0.5 + step * float(col + 1)
		var pz: float = -PLATE_SIZE * 0.25 + float(row) * (PLATE_SIZE * 0.5)
		peg.position = Vector3(px, 0.06 + PEG_HEIGHT * 0.5, pz)
		_add_owned(peg)


## "the room's shape is moral" — six seats on a circle, every one of them facing
## the others. Nobody is at the head of a ring.
func _build_seat_ring() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.5, 0.42, 1.0)
	mat.roughness = 0.8
	for i in SEAT_COUNT:
		var angle: float = deg_to_rad(SEAT_PHASE_DEG) + TAU * float(i) / float(SEAT_COUNT)
		var seat := MeshInstance3D.new()
		var seat_box := BoxMesh.new()
		seat_box.size = Vector3(SEAT_SIZE, SEAT_SIZE, SEAT_SIZE)
		seat.mesh = seat_box
		seat.material_override = mat
		seat.position = Vector3(
			sin(angle) * SEAT_RADIUS,
			SEAT_SIZE * 0.5,
			cos(angle) * SEAT_RADIUS)
		seat.rotation.y = angle
		_add_owned(seat)


# ═══════════════════════════════════════════════════════════════════
# DROPPED — the principles put down
# ═══════════════════════════════════════════════════════════════════

func _build_fallen_board() -> void:
	var board := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.8, 0.03)
	board.mesh = box
	var mat := StandardMaterial3D.new()
	# The back of the board: same stock, none of the writing. Slightly duller than
	# the written face so the still reads "reverse side", not "blank clipboard".
	mat.albedo_color = Color(
		clipboard_color.r * 0.82,
		clipboard_color.g * 0.82,
		clipboard_color.b * 0.82,
		1.0)
	mat.roughness = 0.9
	mat.metallic = 0.0
	board.material_override = mat
	# Face down on the floor at the stand's foot: rotated +90 degrees about X so the
	# written face (+Z) points at the ground.
	board.position = Vector3(0, 0.016, DROPPED_OFFSET_Z)
	board.rotation.x = PI * 0.5
	_add_owned(board)
