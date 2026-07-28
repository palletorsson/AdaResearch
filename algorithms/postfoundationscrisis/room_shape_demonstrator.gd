# Room Shape Demonstrator — the room's geometry IS the policy
#
# A scale model of a room sits on a pedestal. The room has two seating arrangements
# visible: a long table with one chair at the head (centralized authority) and the same
# room with seats arranged in a circle (distributed). Toggle indicators show which
# arrangement each implies — a *who can speak first* question encoded in the floor plan.
#
# Pairs with ethical_design_clipboard: the clipboard names the principles, this artifact
# shows the geometry. Room shape is not neutral.
#
# @identity
# essence: one scale-model room seated twice — a long table with a single chair at its head, and the same walls with the chairs in a circle — so the floor plan itself answers who may speak first
# desire: to make architecture confess that it is policy; the ethics room needs an object where the moral variable is furniture, not text
# critical_parameter: the seating arrangement — head-of-table versus circle; nothing else differs between the two model rooms, so the arrangement carries the whole argument
# triggers: _ready() builds the pedestal, both room models, and the toggle indicators; passive exhibit, read by walking around it
# emerges: the recognition that neutrality was never on the menu — every room you have ever entered had already decided its politics before you arrived
# needs: BoxMesh walls and chairs [Godot built-ins]; a pedestal at examination height; pairs with ethical_design_clipboard which names the principles this shows
# relationships: the applied rung of the ethics ladder — bias_from_inside says the classifier has an inside, this says the meeting room does too
# truth: room shape is not neutral. Who can speak first is encoded in the floor plan, and redesign is therefore a moral act, not a decorative one.
# @qfep_term: Edge — what the architecture forecloses.

extends Node3D
class_name RoomShapeDemonstrator

@export var room_color: Color = Color(0.8, 0.76, 0.7, 1.0)
@export var chair_color_authority: Color = Color(0.95, 0.45, 0.35, 1.0)
@export var chair_color_distributed: Color = Color(0.5, 0.85, 0.55, 1.0)
@export var room_size: Vector3 = Vector3(1.6, 0.5, 1.0)
@export var pedestal_height: float = 0.8

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS — plan
# ═══════════════════════════════════════════════════════════════════

## Which seating politics the model presents, and — the part that actually matters —
## whether it is offered as a COMPARISON or as the way things are. The artifact used to
## be permanently two-up with the good option colour-coded green, which makes the moral
## argument for the viewer before they have looked at anything. `head` and `circle` put
## ONE plan on ONE pedestal at 1.5x, so the plan has to be inhabited rather than scored
## against its neighbour. `panopticon` supplies the arrangement the pair conspicuously
## omits. `vacant` builds both rooms with no furniture at all — the neutral floor plan
## whose neutrality is the exact fiction this artifact exists to attack.
##
## Pedestal count, room scale, table shape, chair count and chair facing all move
## together, so no two values can read as the same tile from across the room.
@export_enum("pair", "head", "circle", "panopticon", "vacant") var plan: String = "pair"

## Allow-list for the axis. A typo in a map token lands on the legacy two-up look
## rather than half-applying and stranding a placement with an empty pedestal.
const PLANS: PackedStringArray = ["pair", "head", "circle", "panopticon", "vacant"]

## How much bigger a single-plan model gets. 1.5 turns the 1.6 x 0.5 x 1.0 room into
## 2.4 x 0.75 x 1.5 — a change of nearly a metre across, decisive from walking distance.
## A polite 10% would have read as the same model and been worthless.
const SOLO_SCALE: float = 1.5

## Panopticon ring: wall radius, chair ring radius, occupant count, and how much
## taller the centre chair stands than the ones on the rim.
const PANOPTICON_RADIUS: float = 0.55
const PANOPTICON_SEATS: int = 8
const PANOPTICON_SEAT_RING: float = 0.42
const PANOPTICON_WALL_SEGMENTS: int = 24
const PANOPTICON_TOWER_SCALE: float = 1.6

## Pale tan — the colour the long-table room already uses for everyone who is not at
## the head. Reused on the panopticon rim so the two rooms speak one colour grammar:
## red is whoever the geometry hands the floor to, tan is everybody else.
const CHAIR_COLOR_SUBORDINATE: Color = Color(0.7, 0.6, 0.55, 1.0)

var _built: bool = false

## Every node THIS script parented to self, in creation order. The rebuild frees this
## list and nothing else — label plates, packaging and tags added by the grid system
## are other people's children and must survive a reconfigure.
var _parts: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	# Stage-2 DNA axis — #plan:panopticon
	var before_plan: String = plan
	if config_data.has("plan"):
		plan = _pick_axis(str(config_data["plan"]), PLANS, plan)

	# On the normal grid path this runs BEFORE add_child, so _ready has not fired and
	# there is nothing built to rebuild. _ready will build with the values just set.
	if not _built:
		return
	# curation_station hands us {"emissive": false} after it has already framed our
	# labels. Nothing geometric changed, so we touch nothing and say nothing.
	if plan == before_plan:
		return
	_rebuild_now()
	print("[RoomShapeDemonstrator] Config applied — plan=%s" % [plan])


## Accept an axis value only if it names something we actually build. A typo in a
## map token has to fall back to the legacy look — a half-recognised value would
## leave a bare pedestal where a room used to be.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous teardown and rebuild. remove_child leaves the tree immediately, so the
## old plan never renders alongside the new one, and no call_deferred means we land
## before the grid's label framing and auto-grounding rather than after them.
func _rebuild_now() -> void:
	for c in _parts:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_parts.clear()
	_build_all()


## Parent a node we built and remember it, so the next rebuild can find it again.
func _add_part(n: Node) -> void:
	add_child(n)
	_parts.append(n)


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	match plan:
		"head":
			# One plan, one pedestal, 1.5x. Nothing to compare it against — you are
			# standing in the room that has a head of the table, not judging it.
			_build_pedestals([0.0], SOLO_SCALE)
			_build_centralized_room(_origin_for(0.0, SOLO_SCALE), SOLO_SCALE, true)
			_build_label("centralized", 0.0, SOLO_SCALE, chair_color_authority)
		"circle":
			_build_pedestals([0.0], SOLO_SCALE)
			_build_distributed_room(_origin_for(0.0, SOLO_SCALE), SOLO_SCALE, true)
			_build_label("distributed", 0.0, SOLO_SCALE, chair_color_distributed)
		"panopticon":
			# The arrangement the two-up comparison never offers: nobody at a table,
			# everybody at the rim facing out, one chair in the middle looking at them.
			_build_pedestals([-1.0, 1.0], 1.0)
			_build_centralized_room(_origin_for(-1.0, 1.0), 1.0, true)
			_build_panopticon_room(_origin_for(1.0, 1.0), 1.0)
			_build_label("centralized", -1.0, 1.0, chair_color_authority)
			_build_label("panopticon", 1.0, 1.0, chair_color_authority)
		"vacant":
			# Walls and floors exactly as always, and not one stick of furniture.
			# This is the drawing an architect calls neutral.
			_build_pedestals([-1.0, 1.0], 1.0)
			_build_centralized_room(_origin_for(-1.0, 1.0), 1.0, false)
			_build_distributed_room(_origin_for(1.0, 1.0), 1.0, false)
			_build_label("unfurnished", -1.0, 1.0, room_color)
			_build_label("unfurnished", 1.0, 1.0, room_color)
		_:
			# "pair" — the legacy look, unchanged.
			_build_pedestals([-1.0, 1.0], 1.0)
			_build_centralized_room(_origin_for(-1.0, 1.0), 1.0, true)
			_build_distributed_room(_origin_for(1.0, 1.0), 1.0, true)
			_build_label("centralized", -1.0, 1.0, chair_color_authority)
			_build_label("distributed", 1.0, 1.0, chair_color_distributed)


func _origin_for(x_off: float, s: float) -> Vector3:
	return Vector3(x_off, pedestal_height + room_size.y * s * 0.5, 0.0)


func _build_pedestals(offsets: Array, s: float) -> void:
	for x_off in offsets:
		var ped := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(room_size.x * s + 0.2 * s, pedestal_height, room_size.z * s + 0.2 * s)
		ped.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.32, 0.38, 1.0)
		mat.roughness = 0.7
		ped.material_override = mat
		ped.position = Vector3(float(x_off), pedestal_height * 0.5, 0)
		_add_part(ped)


func _build_centralized_room(origin: Vector3, s: float, furnished: bool) -> void:
	# Walls — three sides only, so the model is visible.
	_build_room_walls(origin, room_color, room_size * s)
	if not furnished:
		return
	var floor_y: float = -room_size.y * s * 0.5
	# Long table.
	var table := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0 * s, 0.04 * s, 0.18 * s)
	table.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.4, 0.3, 1.0)
	table.material_override = mat
	table.position = origin + Vector3(0, floor_y + 0.16 * s, 0)
	_add_part(table)
	# Head-of-table chair.
	var chair := _make_chair(chair_color_authority)
	chair.scale = Vector3(s, s, s)
	chair.position = origin + Vector3(0.6 * s, floor_y + 0.1 * s, 0)
	_add_part(chair)
	# Other chairs (smaller, lighter — they have less floor presence).
	for x_off in [-0.3, 0.0, 0.3]:
		for z_off in [-0.18, 0.18]:
			var c := _make_chair(CHAIR_COLOR_SUBORDINATE)
			c.scale = Vector3(0.6 * s, 0.6 * s, 0.6 * s)
			c.position = origin + Vector3(float(x_off) * s, floor_y + 0.06 * s, float(z_off) * s)
			_add_part(c)


func _build_distributed_room(origin: Vector3, s: float, furnished: bool) -> void:
	_build_room_walls(origin, room_color, room_size * s)
	if not furnished:
		return
	var floor_y: float = -room_size.y * s * 0.5
	# Round table.
	var table := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.25 * s
	cyl.bottom_radius = 0.25 * s
	cyl.height = 0.04 * s
	table.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.4, 0.3, 1.0)
	table.material_override = mat
	table.position = origin + Vector3(0, floor_y + 0.16 * s, 0)
	_add_part(table)
	# Six equal chairs in a circle.
	for i in 6:
		var a: float = TAU * float(i) / 6.0
		var chair := _make_chair(chair_color_distributed)
		chair.scale = Vector3(s, s, s)
		chair.position = origin + Vector3(cos(a) * 0.4 * s, floor_y + 0.1 * s, sin(a) * 0.4 * s)
		_add_part(chair)


## The plan the comparison leaves out. A drum wall instead of a rectangle, no table at
## all, eight occupants pushed to the rim FACING OUT so none of them can see each other,
## and a single tall chair on the centre line that can see all eight. Backs are modelled
## here (they are not on the other chairs) because facing is the whole argument and a
## featureless cube has no front.
func _build_panopticon_room(origin: Vector3, s: float) -> void:
	var radius: float = PANOPTICON_RADIUS * s
	var wall_h: float = room_size.y * s
	var floor_y: float = -wall_h * 0.5

	# Floor plate.
	var plate := MeshInstance3D.new()
	var plate_mesh := CylinderMesh.new()
	plate_mesh.top_radius = radius
	plate_mesh.bottom_radius = radius
	plate_mesh.height = 0.04 * s
	plate.mesh = plate_mesh
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = room_color
	plate_mat.roughness = 0.9
	plate.material_override = plate_mat
	plate.position = origin + Vector3(0, floor_y, 0)
	_add_part(plate)

	# Drum wall, built from segments so it reads as a wall you could stand inside
	# rather than a solid post.
	var seg_w: float = TAU * radius / float(PANOPTICON_WALL_SEGMENTS) * 1.15
	for i in PANOPTICON_WALL_SEGMENTS:
		var a: float = TAU * float(i) / float(PANOPTICON_WALL_SEGMENTS)
		var seg := MeshInstance3D.new()
		var seg_box := BoxMesh.new()
		seg_box.size = Vector3(seg_w, wall_h, 0.04 * s)
		seg.mesh = seg_box
		var seg_mat := StandardMaterial3D.new()
		seg_mat.albedo_color = room_color
		seg_mat.roughness = 0.9
		seg.material_override = seg_mat
		seg.position = origin + Vector3(cos(a) * radius, 0, sin(a) * radius)
		seg.rotation.y = -a
		_add_part(seg)

	# Eight cells at the rim, every one of them facing outward at the wall.
	for i in PANOPTICON_SEATS:
		var a: float = TAU * float(i) / float(PANOPTICON_SEATS)
		var cell := _make_facing_chair(CHAIR_COLOR_SUBORDINATE)
		cell.scale = Vector3(s, s, s)
		cell.position = origin + Vector3(
			cos(a) * PANOPTICON_SEAT_RING * s,
			floor_y + 0.1 * s,
			sin(a) * PANOPTICON_SEAT_RING * s)
		# Local +Z is the seat's front; point it away from the centre.
		cell.rotation.y = atan2(cos(a), sin(a))
		_add_part(cell)

	# The tower. Same chair, 1.6x tall, on the centre line.
	var tower := _make_chair(chair_color_authority)
	tower.scale = Vector3(s, PANOPTICON_TOWER_SCALE * s, s)
	tower.position = origin + Vector3(0, floor_y + 0.09 * PANOPTICON_TOWER_SCALE * s + 0.01 * s, 0)
	_add_part(tower)


func _build_room_walls(origin: Vector3, color: Color, dims: Vector3) -> void:
	for wall_data in [
		{"size": Vector3(dims.x, dims.y, 0.04), "pos": Vector3(0, 0, -dims.z * 0.5)},
		{"size": Vector3(0.04, dims.y, dims.z), "pos": Vector3(-dims.x * 0.5, 0, 0)},
		{"size": Vector3(0.04, dims.y, dims.z), "pos": Vector3(dims.x * 0.5, 0, 0)},
		{"size": Vector3(dims.x, 0.04, dims.z), "pos": Vector3(0, -dims.y * 0.5, 0)},
	]:
		var wall := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = wall_data["size"]
		wall.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.9
		wall.material_override = mat
		wall.position = origin + wall_data["pos"]
		_add_part(wall)


func _make_chair(color: Color) -> MeshInstance3D:
	var chair := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 0.18, 0.1)
	chair.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.4
	chair.material_override = mat
	return chair


## A chair with a back, so which way it points is legible. Only the panopticon uses it —
## the other rooms keep their featureless cubes exactly as before.
func _make_facing_chair(color: Color) -> Node3D:
	var root := Node3D.new()
	root.add_child(_make_chair(color))
	var back := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 0.16, 0.03)
	back.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.4
	back.material_override = mat
	back.position = Vector3(0, 0.1, -0.065)
	root.add_child(back)
	return root


func _build_label(text: String, x_off: float, s: float, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 22
	l.modulate = color
	l.position = Vector3(x_off, pedestal_height + room_size.y * s + 0.25, 0)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_add_part(l)
