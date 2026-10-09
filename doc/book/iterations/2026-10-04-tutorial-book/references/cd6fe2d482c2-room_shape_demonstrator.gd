# Room Shape Demonstrator — furniture proposes relations before anyone speaks.
# @identity
# essence: authored miniature seating plans; count, scale, table geometry and facing can change together
# desire: compare the invitations a plan makes, then question the comparison itself
# critical_parameter: plan; palette separately exposes the original red/green persuasion
# triggers: optional visitor panel selects five existing plans and two palettes
# emerges: equal angular spacing is visible; equal participation requires evidence with people
# needs: model pedestals, accessible controls and room to view the models from several sides
# relationships: word positions in the previous hall become possible participant positions here
# truth: these models contain no speech, listening, assigned turn or measured accessibility
# @qfep_term: Edge — what an arrangement offers and what the model leaves out.

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
## ONE miniature plan on ONE pedestal at 1.5x, examined on its own before comparison. `panopticon` supplies the arrangement the pair conspicuously
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
## red marks the author-designated head or centre; it does not grant a speaking turn.
const CHAIR_COLOR_SUBORDINATE: Color = Color(0.7, 0.6, 0.55, 1.0)

@export var interactive: bool = false
@export_enum("authored", "neutral") var palette: String = "authored"
const NEUTRAL_CHAIR := Color(0.65, 0.7, 0.75)
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")
var _console: Node3D
var _panel: Node3D
var _status: MeshInstance3D
var _built: bool = false

## Every node THIS script parented to self, in creation order. The rebuild frees this
## list and nothing else — label plates, packaging and tags added by the grid system
## are other people's children and must survive a reconfigure.
var _parts: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true
	_sync_console()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	# Stage-2 DNA axis — #plan:panopticon
	var before_plan: String = plan
	var before_palette: String = palette
	var before_interactive: bool = interactive
	if config_data.has("plan"):
		plan = _pick_axis(str(config_data["plan"]), PLANS, plan)

	if config_data.has("palette"):
		palette = _pick_axis(str(config_data["palette"]), PackedStringArray(["authored", "neutral"]), palette)
	if config_data.has("interactive"):
		interactive = str(config_data["interactive"]).to_lower() in ["true", "1"]

	# On the normal grid path this runs BEFORE add_child, so _ready has not fired and
	# there is nothing built to rebuild. _ready will build with the values just set.
	if not _built:
		return
	# curation_station hands us {"emissive": false} after it has already framed our
	# labels. Nothing geometric changed, so we touch nothing and say nothing.
	if plan != before_plan or palette != before_palette or interactive != before_interactive:
		_rebuild_now()
	_sync_console()


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
			# examining a miniature with a head position before seeing its partner.
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
		if interactive:
			var body := StaticBody3D.new()
			body.name = "ModelPedestal"
			body.position = ped.position
			var collider := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = box.size
			collider.shape = shape
			body.add_child(collider)
			_add_part(body)


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
## all, eight backed seats face outward and a tall block marks the centre.
## There are no occupants, sightline sensors or actual watchers in this model. Backs are modelled
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
		# A wall follows the tangent, rather than pointing radially into the room.
		seg.rotation.y = PI * 0.5 - a
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
	if palette == "neutral": color = NEUTRAL_CHAIR
	var chair := MeshInstance3D.new()
	chair.set_meta("room_shape_chair", true)
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
	if palette == "neutral": color = NEUTRAL_CHAIR
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
	if interactive:
		var names := {"centralized":"LONG TABLE · 7", "distributed":"CIRCLE · 6", "panopticon":"RIM + CENTRE · 9", "unfurnished":"UNFURNISHED · 0"}
		var plate := BakedText.make_panel_mesh(names.get(text,text),Color(.07,.08,.1),Color(.9,.92,.95),Vector2(.65,.07),900,true)
		plate.position=Vector3(x_off,pedestal_height+room_size.y*s+.15,0)
		plate.material_override.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
		_add_part(plate)
		return
	var l := Label3D.new()
	l.text = text
	l.font_size = 22
	l.modulate = color
	l.position = Vector3(x_off, pedestal_height + room_size.y * s + 0.25, 0)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_add_part(l)


func _sync_console() -> void:
	if not interactive:
		if is_instance_valid(_console): _console.hide()
		return
	if not is_instance_valid(_console):
		_console=Node3D.new()
		_console.name="PlanConsole"
		add_child(_console)
		var rack: GDScript=load("res://commons/audio/rack_templates/RackTemplates.gd")
		_panel=rack.create_panel("ARRANGE",[
			[{"type":"button","label":"HEAD"},{"type":"button","label":"CIRCLE"},{"type":"button","label":"PAIR"}],
			[{"type":"button","label":"WATCH"},{"type":"button","label":"VACANT"}],
			[{"type":"button","label":"NEUTRAL"},{"type":"button","label":"COLOUR"}]
		])
		_panel.position=Vector3(0,1.02,1.18)
		_panel.rotation_degrees.x=-20
		_panel.scale=Vector3.ONE*1.5
		_console.add_child(_panel)
		var choices: Array[String]=["head","circle","pair","panopticon","vacant"]
		for i in range(5):
			_panel.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.connect(_choose_plan.bind(choices[i]))
		_panel.find_child("Btn_5",true,false).get_node("InteractableAreaButton").button_pressed.connect(_choose_palette.bind("neutral"))
		_panel.find_child("Btn_6",true,false).get_node("InteractableAreaButton").button_pressed.connect(_choose_palette.bind("authored"))
		var stand:=MeshInstance3D.new()
		var mesh:=CylinderMesh.new()
		mesh.height=.9
		mesh.top_radius=.06
		mesh.bottom_radius=.15
		stand.mesh=mesh
		stand.position=Vector3(0,.45,1.09)
		var mat:=StandardMaterial3D.new()
		mat.albedo_color=Color(.2,.22,.25)
		stand.material_override=mat
		_console.add_child(stand)
	_console.show()
	if is_instance_valid(_status):
		_console.remove_child(_status)
		_status.queue_free()
	_status=BakedText.make_panel_mesh(plan.to_upper()+" · "+palette.to_upper(),Color(.07,.08,.1),Color(.9,.92,.95),Vector2(.55,.055),900,true)
	_status.position=Vector3(0,1.38,1.18)
	_console.add_child(_status)


func _choose_plan(_body: Variant, choice: String) -> void:
	apply_grid_config({"plan":choice})


func _choose_palette(_body: Variant, choice: String) -> void:
	apply_grid_config({"palette":choice})
