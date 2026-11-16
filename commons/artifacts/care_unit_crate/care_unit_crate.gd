extends Node3D
## THE OTHER THREE (floor Point_Zero; Palle, 2026-11-16)
##
## "Put three Care Unit Model B in a transport wooden crate, as they were also transported with the box, but this
## was the model that woke up." The visitor is delivered in a crate lettered CARE UNIT - MODEL B and breaks out
## of it. Beside it stands the rest of the consignment: one more crate with the same lettering, slatted at the
## front, and in it three more bodies of the same model, strapped in their bays, tagged, and not awake. Nothing
## happens here. They are what the visitor was a minute ago.
##
## The bodies are the visitor's own body (commons/void/ada_android.gd), unpainted and with nothing lit. That
## script is looked for when the crate is built; where it is absent a plain packed figure stands in each bay.
##
## `face` is the axis: slatted (the three are seen between the boards), closed (a crate like any other: the
## lettering is all there is to go on), open (no boards across the front).
##
## ONE BOX (Palle, the same day: "Will the player step out of that box as one of the units? Then should we remove
## the other box?"). With `shell` off the work is only the bays: a row that stands INSIDE the arrival crate, against
## its back wall, behind the place where the visitor wakes. `bays` is how many, `empty` which one has nobody in
## it: its straps hang open and its tag says UNIT 1 OF 4. That bay is the visitor's.
const WIDE := 3.0
const DEEP := 1.15
const HIGH := 2.35
const BASE := 0.12                        # the skids and the floor boards
const BOARD := 0.035
const BAYS: Array[float] = [-0.95, 0.0, 0.95]
const FACES := ["slatted", "closed", "open"]
const ANDROID := "res://commons/void/ada_android.gd"
const MARK := "res://commons/void/textures/care-unit-mark.png"
const PLANK := Color("c9bc91")
const PLANK_ALT := Color("bcaf83")
const STRIP := Color("ada17b")
const FOAM := Color("2b2c33")
const STRAP := Color("15151a")
const TAG := Color("e9e2cf")

@export_enum("slatted", "closed", "open") var face := "slatted"
@export var shell := true                 # off: no crate of its own, only the bays
@export var bays := 3
@export var empty := -1                   # which bay stands empty (0 is the first); -1: none

var _grain: ImageTexture
var _slats: Node3D
var _planks: Node3D
var _units: Array[Node3D] = []
var _kind := "figure"
var _build_ms := 0


func _ready() -> void:
	var given := {}
	for key in ["face", "shell", "bays", "empty"]:
		if has_meta("config_" + key): given[key] = get_meta("config_" + key)
	_take(given)
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("face") and FACES.has(str(config_data["face"])): face = str(config_data["face"])
	if config_data.has("shell"): shell = not (str(config_data["shell"]).to_lower() in ["off", "false", "0", "no"])
	if config_data.has("bays"): bays = clampi(int(str(config_data["bays"])), 1, 4)
	if config_data.has("empty"): empty = int(str(config_data["empty"]))


## The tower hands a row its config after the work is built: what changes the build is built again.
func apply_grid_config(config_data: Dictionary) -> void:
	var before := [face, shell, bays, empty]
	_take(config_data)
	if not is_inside_tree() or _slats == null or before == [face, shell, bays, empty]: return
	if before.slice(1) != [shell, bays, empty]:
		for child in get_children():
			remove_child(child)
			child.queue_free()
		_units.clear()
		_kind = "figure"
		_build_once()
	_found()


func _found() -> void:
	_slats.visible = face == "slatted"
	_planks.visible = face == "closed"


## ---- building, once ----

func _wood(colour: Color) -> StandardMaterial3D:
	if _grain == null:
		var image := Image.create(128, 256, false, Image.FORMAT_RGB8)
		var noise := FastNoiseLite.new()
		noise.seed = 731
		noise.frequency = 0.06
		for y in 256:
			for x in 128:
				var bend: float = noise.get_noise_2d(x * 0.3, y * 0.18) * 5.0
				var value: float = clampf(0.94 + sin((float(x) + bend) * 1.5) * 0.025 + noise.get_noise_2d(x * 2.0, y * 0.2) * 0.10, 0.7, 1.0)
				image.set_pixel(x, y, Color(value, value, value))
		_grain = ImageTexture.create_from_image(image)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.albedo_texture = _grain
	paint.roughness = 0.92
	paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return paint


func _flat(colour: Color, rough := 0.85) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.roughness = rough
	return paint


func _box(parent: Node3D, at: Vector3, size: Vector3, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = paint
	mesh.position = at
	parent.add_child(mesh)
	return mesh


## A wall of upright boards between two corners, `wide` along x (or along z when `turned`).
func _boards(parent: Node3D, centre: Vector3, wide: float, tall: float, turned: bool, count: int) -> void:
	var each: float = wide / float(count)
	for i in count:
		var along: float = -wide * 0.5 + each * (float(i) + 0.5)
		var size := Vector3(BOARD, tall, each - 0.006) if turned else Vector3(each - 0.006, tall, BOARD)
		var at := centre + (Vector3(0, 0, along) if turned else Vector3(along, 0, 0))
		_box(parent, at, size, _wood(PLANK if i % 2 == 0 else PLANK_ALT))


func _mark(parent: Node3D, at: Vector3) -> void:
	if not ResourceLoader.exists(MARK): return
	var ink := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.25, 0.17)
	ink.mesh = quad
	var paint := StandardMaterial3D.new()
	paint.albedo_texture = load(MARK) as Texture2D
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	paint.alpha_scissor_threshold = 0.3
	paint.roughness = 1.0
	ink.material_override = paint
	ink.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ink.position = at
	parent.add_child(ink)


func _label(parent: Node3D, at: Vector3, text: String, size: int, colour: Color) -> Label3D:
	var words := Label3D.new()
	words.text = text
	words.font_size = size
	words.pixel_size = 0.002
	words.modulate = colour
	words.outline_size = 0
	words.position = at
	parent.add_child(words)
	return words


## One of the three: the visitor's own body, unpainted, nothing lit - or a packed figure where that body's
## script is not to be found.
func _unit() -> Node3D:
	if ResourceLoader.exists(ANDROID):
		var script := load(ANDROID) as GDScript
		if script != null:
			var body := script.new() as Node3D
			if body != null and body.has_method("assemble"):
				body.call("assemble", 1, false, false)
				var lit: Variant = body.get("_pink")
				if lit is StandardMaterial3D:
					(lit as StandardMaterial3D).emission_enabled = false
					(lit as StandardMaterial3D).albedo_color = Color("5b3a4a")
				body.rotation.y = PI          # the body is built facing -z; the bays face the front of the crate
				_kind = "android"
				return body
	var figure := Node3D.new()
	var wrap := _flat(Color("6f6a62"), 0.95)
	var trunk := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.2
	capsule.height = 1.5
	trunk.mesh = capsule
	trunk.material_override = wrap
	trunk.position = Vector3(0, 0.75, 0)
	figure.add_child(trunk)
	var head := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.13
	ball.height = 0.26
	head.mesh = ball
	head.material_override = wrap
	head.position = Vector3(0, 1.62, 0)
	figure.add_child(head)
	return figure


func _build_once() -> void:
	var front: float = DEEP * 0.5
	var top: float = BASE + HIGH
	_slats = Node3D.new()
	_slats.name = "Slats"
	add_child(_slats)
	_planks = Node3D.new()
	_planks.name = "Planks"
	add_child(_planks)
	if shell: _build_shell(front, top)
	_build_bays()


func _build_shell(front: float, top: float) -> void:
	# skids and floor
	for x in [-WIDE * 0.5 + 0.2, 0.0, WIDE * 0.5 - 0.2]: _box(self, Vector3(x, 0.04, 0), Vector3(0.16, 0.08, DEEP), _wood(STRIP))
	_box(self, Vector3(0, BASE - 0.02, 0), Vector3(WIDE, 0.04, DEEP), _wood(PLANK_ALT))
	# back, two ends, lid
	_boards(self, Vector3(0, BASE + HIGH * 0.5, -front), WIDE, HIGH, false, 9)
	_boards(self, Vector3(-WIDE * 0.5, BASE + HIGH * 0.5, 0), DEEP, HIGH, true, 4)
	_boards(self, Vector3(WIDE * 0.5, BASE + HIGH * 0.5, 0), DEEP, HIGH, true, 4)
	_box(self, Vector3(0, top, 0), Vector3(WIDE + 0.04, BOARD, DEEP + 0.04), _wood(PLANK))
	# corner posts, and battens round the top and the bottom
	for x in [-WIDE * 0.5, WIDE * 0.5]:
		for z in [-front, front]: _box(self, Vector3(x, BASE + HIGH * 0.5, z), Vector3(0.09, HIGH, 0.09), _wood(STRIP))
	for y in [BASE + 0.07, top - 0.07]:
		_box(self, Vector3(0, y, -front - 0.03), Vector3(WIDE, 0.12, 0.05), _wood(STRIP))
		for x in [-WIDE * 0.5 - 0.03, WIDE * 0.5 + 0.03]: _box(self, Vector3(x, y, 0), Vector3(0.05, 0.12, DEEP), _wood(STRIP))
	# the front, three ways
	for y in [BASE + 0.26, BASE + 1.02, BASE + 2.1]: _box(_slats, Vector3(0, y, front), Vector3(WIDE, 0.2, BOARD), _wood(PLANK if y < 1.0 or y > 2.0 else PLANK_ALT))
	_mark(_slats, Vector3(-0.2, BASE + 2.1, front + BOARD * 0.5 + 0.002))
	_label(_slats, Vector3(1.0, BASE + 0.26, front + BOARD * 0.5 + 0.002), "QTY 3", 58, Color("1c1a17"))
	_boards(_planks, Vector3(0, BASE + HIGH * 0.5, front), WIDE, HIGH, false, 9)
	_mark(_planks, Vector3(-0.2, BASE + 1.75, front + BOARD * 0.5 + 0.002))
	_label(_planks, Vector3(1.0, BASE + 1.45, front + BOARD * 0.5 + 0.002), "QTY 3", 58, Color("1c1a17"))
	# what holds a body off: the crate is a solid thing
	var solid := StaticBody3D.new()
	solid.name = "Solid"
	add_child(solid)
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = Vector3(WIDE + 0.1, top, DEEP + 0.1)
	shape.shape = block
	shape.position = Vector3(0, top * 0.5, 0)
	solid.add_child(shape)
	# dividers between the bays
	for x in [-0.475, 0.475]: _box(self, Vector3(x, BASE + HIGH * 0.5, -0.05), Vector3(BOARD, HIGH, DEEP - 0.14), _wood(PLANK_ALT))


## The bays: a body, foam at the shoulders and the ankles, two straps, a tag. One bay may stand empty, its straps
## hanging open: the place of the one that woke.
func _build_bays() -> void:
	var pitch: float = 0.95 if shell else 0.76
	var floor_at: float = BASE if shell else 0.0
	var number := 2
	for k in bays:
		var bay := Node3D.new()
		var vacant: bool = k == empty
		bay.name = "Bay%d" % (1 if vacant else number)
		bay.position = Vector3((float(k) - float(bays - 1) * 0.5) * pitch, floor_at, -0.08 if shell else 0.0)
		add_child(bay)
		var reach: float = pitch * 0.5 - 0.07
		for side in [-1.0, 1.0]:
			_box(bay, Vector3(side * reach, 1.36, 0), Vector3(0.12, 0.3, 0.5), _flat(FOAM, 0.98))
			_box(bay, Vector3(side * (reach - 0.05), 0.14, 0), Vector3(0.14, 0.28, 0.5), _flat(FOAM, 0.98))
		_box(bay, Vector3(0, 1.9, -0.2), Vector3(0.5, 0.16, 0.2), _flat(FOAM, 0.98))
		var tag: MeshInstance3D
		if vacant:
			# the straps hang open from either side
			for y in [0.62, 1.22]:
				for side in [-1.0, 1.0]:
					var loose := Node3D.new()
					loose.position = Vector3(side * (pitch * 0.5 - 0.03), y, 0.2)
					loose.rotation_degrees.z = side * (78.0 if y > 1.0 else 84.0)
					bay.add_child(loose)
					_box(loose, Vector3(-side * (pitch * 0.25 - 0.03), 0, 0), Vector3(pitch * 0.5 - 0.06, 0.05, 0.012), _flat(STRAP, 0.6))
			tag = _box(bay, Vector3(pitch * 0.5 - 0.1, 0.8, 0.215), Vector3(0.17, 0.11, 0.004), _flat(TAG, 0.9))
			tag.rotation_degrees.z = 12.0
			var mine: Label3D = _label(tag, Vector3(0, 0, 0.004), "MODEL B\nUNIT 1 OF 4", 22, Color("1c1a17"))
			mine.pixel_size = 0.0006
			continue
		var unit := _unit()
		unit.name = "Unit"
		bay.add_child(unit)
		_units.append(unit)
		for y in [0.62, 1.22]: _box(bay, Vector3(0, y, 0.2), Vector3(pitch - 0.08, 0.05, 0.012), _flat(STRAP, 0.6))
		tag = _box(bay, Vector3(0.24, 1.08, 0.215), Vector3(0.17, 0.11, 0.004), _flat(TAG, 0.9))
		tag.rotation_degrees.z = -7.0
		var words: Label3D = _label(tag, Vector3(0, 0, 0.004), "MODEL B\nUNIT %d OF 4\nNOT ACTIVATED" % number, 22, Color("1c1a17"))
		words.pixel_size = 0.0006
		number += 1
	if not shell:
		# a row inside another crate: a body cannot walk through the packed ones
		var held := StaticBody3D.new()
		held.name = "Row"
		add_child(held)
		var shape := CollisionShape3D.new()
		var block := BoxShape3D.new()
		block.size = Vector3(float(bays) * pitch, 2.0, 0.5)
		shape.shape = block
		shape.position = Vector3(0, 1.0, 0)
		held.add_child(shape)


## ---- for a test ----

func state() -> Dictionary:
	return {"face": face, "shell": shell, "bays": bays, "empty": empty, "units": _units.size(), "kind": _kind, "slats_shown": _slats.visible, "planks_shown": _planks.visible, "build_ms": _build_ms,
		"unit_places": _units.map(func(u): return [u.global_position.x, u.global_position.y, u.global_position.z])}


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
