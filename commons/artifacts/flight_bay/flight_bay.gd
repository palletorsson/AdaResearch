class_name FlightBay
extends "res://commons/movement/museum_flight_box.gd"
## THE FLIGHT BAY (Palle, 2026-11-02: "start with the flight bay in the biome court"). The first glass bay of the
## playground plan (doc/plans/biome-ladder/PLAYGROUND_HANDOVER.md, "Glass bays, biome strata and workers across the
## spine"): a box of air with glass walls, installed in a host like any other activity (the hall sidecar's
## `activities`). It changes locomotion, not what it holds. Inside we fly with the museum's flight - the same group,
## velocity, desktop walker, XR movement provider and the Void's fall rule (museum_flight_box.gd) - outside gravity
## returns.
##
## The contract (config_* metas, or apply_grid_config):
##   width x depth x height  the flying volume, metres, from the bay's origin up (the origin is the volume's floor)
##   doors                   the sides with a door at the origin's level: east, west, north, south ("east,west")
##   door_width, door_height the door opening, metres
##   sill                    the glass begins this high above the origin, clearing what the host has at its edge (the
##                           court rim's joint crowns stand 6 cm above the walk); the gap is too low to pass under
##   mode                    flight - the volume changes locomotion; still - the same glass, gravity unchanged (the
##                           control, and the plan's other two modes when they come: concentrated, stratum)
##
## In the biome court the origin is the RIM (y 4), not the bath floor, and the volume has no floor: the court below
## stays a place to walk - the descent ramp, the gaussian floor, the ball test - and the bay is the air above it. Its
## doors are east and west on the rim walk, and south over the descent ramp, which drops under the rim: there the
## door is headroom for the walk down (the ramp stays under the air), and a way out for the flier.
## Step off the rim walk through a door and we hover over the court. Sink below the rim and gravity sets us down on
## its floor; a jump from that floor (4.6 m/s, about 1.08 m) rises back into the air and is caught.

const SIDES := {"east": Vector3.RIGHT, "west": Vector3.LEFT, "south": Vector3.BACK, "north": Vector3.FORWARD}
const GLASS := 0.04
@export var width := 9.9
@export var depth := 9.9
@export var height := 8.0
@export var doors := PackedStringArray(["east", "west"])
@export var door_width := 2.0
@export var door_height := 2.6
@export var sill := 0.0
@export_enum("flight", "still") var mode := "flight"
var envelope: Node3D

func _ready() -> void:
	var config := {}
	for key in ["width", "depth", "height", "doors", "door_width", "door_height", "sill", "mode"]:
		if has_meta("config_" + key): config[key] = get_meta("config_" + key)
	_read(config)
	if instruction_title == "FLY THROUGH THE HOLES": instruction_title = "FLY OVER THE COURT"
	super._ready()
	if mode != "flight": remove_from_group(GROUP)

func apply_grid_config(config: Dictionary) -> void:
	if _read(config) and envelope != null:
		envelope.free()
		_build_enclosure()
		if mode == "flight": add_to_group(GROUP)
		else: remove_from_group(GROUP)

## Takes the contract's keys; true when anything changed.
func _read(config: Dictionary) -> bool:
	var before := [width, depth, height, doors, door_width, door_height, sill, mode]
	for key in ["width", "depth", "height", "door_width", "door_height"]:
		if config.has(key) and str(config[key]).is_valid_float(): set(key, maxf(float(str(config[key])), 0.5))
	if config.has("sill") and str(config.sill).is_valid_float(): sill = clampf(float(str(config.sill)), 0.0, 0.15)
	if config.has("doors"):
		var raw: Variant = config.doors
		var named: Array = []
		if raw is Array or raw is PackedStringArray: named = Array(raw)
		else: named = Array(str(raw).replace("+", ",").split(",", false))
		var kept := PackedStringArray()
		for side in named:
			var s := str(side).strip_edges()
			if SIDES.has(s) and not s in kept: kept.append(s)
			elif s != "": push_warning("flight_bay: unknown door side '%s'" % s)
		doors = kept
	if config.has("mode"):
		if str(config.mode) in ["flight", "still"]: mode = str(config.mode)
		else: push_warning("flight_bay: unknown mode '%s'; kept %s" % [config.mode, mode])
	door_width = minf(door_width, minf(width, depth) - 0.2)
	door_height = minf(door_height, height - 0.2)
	return before != [width, depth, height, doors, door_width, door_height, sill, mode]

## The volume: the glass's inner faces, from the origin up to the roof. It has no floor.
func contains_point(world_position: Vector3) -> bool:
	var p := to_local(world_position)
	return absf(p.x) < width * 0.5 and absf(p.z) < depth * 0.5 and p.y >= -0.03 and p.y < height

func _build_enclosure() -> void:
	envelope = Node3D.new()
	envelope.name = "Envelope"
	add_child(envelope)
	var glass := _material(Color(0.3, 0.7, 0.85, 0.065))
	var frame := _material(Color(0.14, 0.8, 0.94), true)
	for side in SIDES:
		var n: Vector3 = SIDES[side]
		var along := Vector3(absf(n.z), 0, absf(n.x))   # the pane's run
		var half := (width if n.x != 0.0 else depth) * 0.5   # from the centre to this side's inner face
		var run := (depth if n.x != 0.0 else width) + (2.0 * GLASS if n.x != 0.0 else 0.0)   # x sides close the corners
		var at := n * (half + GLASS * 0.5)
		var thick := Vector3(absf(n.x), 0, absf(n.z)) * GLASS
		var tall := height - sill   # every pane stands on the sill
		if side in doors:
			var wing := (run - door_width) * 0.5
			for s in [-1.0, 1.0]:
				_pane(side + "Wing", at + along * s * (door_width + wing) * 0.5 + Vector3.UP * (sill + tall * 0.5), thick + along * wing + Vector3.UP * tall, glass, true)
				_pane(side + "DoorPost", n * half + along * s * (door_width * 0.5 + 0.04) + Vector3.UP * (sill + door_height) * 0.5, Vector3(0.08, door_height - sill, 0.08), frame, false)
			_pane(side + "Lintel", at + Vector3.UP * (height + door_height) * 0.5, thick + along * door_width + Vector3.UP * (height - door_height), glass, true)
			_pane(side + "DoorHead", n * half + Vector3.UP * door_height, along * (door_width + 0.16) + Vector3(0.08, 0.08, 0.08) - along * 0.08, frame, false)
			_door_signs(n, half)
		else:
			_pane(side + "Glass", at + Vector3.UP * (sill + tall * 0.5), thick + along * run + Vector3.UP * tall, glass, true)
		# the side's lit edges: along its head, and its foot - which stops at a door, as the museum's floor edge does
		_pane(side + "Edge", n * half + Vector3.UP * height, along * run + Vector3.ONE * 0.05 - along * 0.05, frame, false)
		if side in doors:
			var wing := (run - door_width) * 0.5
			for s in [-1.0, 1.0]:
				_pane(side + "FootEdge", n * half + along * s * (door_width + wing) * 0.5 + Vector3.UP * (sill + 0.02), along * wing + Vector3.ONE * 0.05 - along * 0.05, frame, false)
		else:
			_pane(side + "FootEdge", n * half + Vector3.UP * (sill + 0.02), along * run + Vector3.ONE * 0.05 - along * 0.05, frame, false)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			_pane("Upright", Vector3(x * width * 0.5, (sill + height) * 0.5, z * depth * 0.5), Vector3(0.07, height - sill, 0.07), frame, false)
	# As the museum's: the camera stands 15 cm above its capsule, so a 24 cm roof keeps the eye inside the glass.
	_pane("Roof", Vector3(0, height - 0.06, 0), Vector3(width + 2.0 * GLASS, 0.24, depth + 2.0 * GLASS), glass, true)

func _pane(label_: String, at: Vector3, size_: Vector3, material: Material, solid: bool) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = label_
	var cube := BoxMesh.new()
	cube.size = size_
	mesh.mesh = cube
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.position = at
	envelope.add_child(mesh, true)   # readable unique names: eastWing, eastWing2
	if solid:
		var body := StaticBody3D.new()
		body.name = label_ + "Collision"
		body.position = at
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size_
		shape.shape = box
		body.add_child(shape)
		envelope.add_child(body, true)

## A sign over each door, outside facing out and inside facing in, so the way back is legible from both sides.
func _door_signs(n: Vector3, half: float) -> void:
	for out in [1.0, -1.0]:
		var mount := Node3D.new()
		mount.name = "DoorSign"
		mount.position = n * (half + out * 0.1) + Vector3.UP * (door_height + 0.55)
		mount.basis = Basis.looking_at(n * out, Vector3.UP, true)   # the label's front (+z) faces away from its pane
		envelope.add_child(mount, true)
		var backing := MeshInstance3D.new()
		var panel := BoxMesh.new()
		panel.size = Vector3(4.9, 0.8, 0.05)
		backing.mesh = panel
		backing.material_override = _material(Color(0.015, 0.035, 0.045))
		mount.add_child(backing)
		var text := Label3D.new()
		text.name = "FlightInstructions"
		text.text = instruction_title + ("\nFlight begins inside the glass" if mode == "flight" else "\nStill glass: gravity holds here") + "\nDesktop: look + WASD / Space up / Ctrl down\nVR: tilt the left controller + left stick\nRelease to hover. Leave by a door, or sink below the rim."
		text.font_size = 40
		text.pixel_size = 0.002
		text.modulate = Color.WHITE if monochrome else Color(0.65, 0.95, 1.0)
		text.outline_size = 8
		text.double_sided = false
		text.position.z = 0.035
		mount.add_child(text)
