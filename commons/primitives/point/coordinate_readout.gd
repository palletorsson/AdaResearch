extends Node3D

# @identity
# essence: the grab point's position as ONE black-and-white wall frame — x, y, z on a white card in a thin dark frame, like the museum's text works
# desire: the coordinate stops floating over the frame and hangs in the hall like a caption — reading a position becomes reading the room
# critical_parameter: axis — "xyz" shows all three lines; "x"|"y"|"z" makes it a single-value frame
# triggers: CoordinateSystem3M broadcasts the grab point's frame-local position to the ada_coordinate_readout group every frame it exists
# emerges: the separation of the measure from the measured — the frame shows WHERE (markers on the axes), the wall says HOW MUCH, in the same voice as the wall's sentences
# needs: [a CoordinateSystem3M with #floating_point:1 somewhere in the hall; shows em-dashes until the point speaks]
# relationships: the words CoordinateSystem3M gave up (#labels:0 #panel:0); styled after the museum's black-and-white text frames; the draw_dot->whiteboard group pattern
# truth: a readout is a promise that someone is measuring — a blank display is an instrument with no experiment

## THE WALL FRAME (2026-08-24, Palle: "the values of coordinate should be in
## one black and white wall frames like the text").
## Map: `coordinate_readout:90:1.4` — rotation faces it, the token's y-offset
## hangs it. Default shows x, y and z as three lines on one white card;
## `#axis:x` narrows it to a single value.

@export var axis: String = "xyz"        # "xyz" | "x" | "y" | "z"
@export var frame_width: float = 0.72
@export var frame_height: float = 0.6

var _label: Label3D = null


func _ready() -> void:
	add_to_group("ada_coordinate_readout")
	_build()


func _build() -> void:
	# the thin dark frame, proud of the wall
	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var fb := BoxMesh.new()
	fb.size = Vector3(frame_width, frame_height, 0.03)
	frame.mesh = fb
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.09, 0.09, 0.1)
	fm.roughness = 0.55
	frame.material_override = fm
	add_child(frame)
	# the white card inside it — the museum text works' own ground
	var card := MeshInstance3D.new()
	card.name = "Card"
	var cb := BoxMesh.new()
	cb.size = Vector3(frame_width - 0.06, frame_height - 0.06, 0.034)
	card.mesh = cb
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.93, 0.925, 0.91)
	cm.roughness = 0.85
	card.material_override = cm
	add_child(card)
	# black text on the card
	_label = Label3D.new()
	_label.name = "Value"
	_label.font_size = 44
	_label.pixel_size = 0.0016
	_label.modulate = Color(0.1, 0.1, 0.12)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.no_depth_test = false
	_label.position = Vector3(0, 0, 0.022)
	add_child(_label)
	_reset_text()


func _reset_text() -> void:
	if _label == null:
		return
	if axis == "xyz":
		_label.text = "x = —\ny = —\nz = —"
	else:
		_label.text = "%s = —" % axis


## Group feed from CoordinateSystem3M: the grab point's frame-local position.
func show_coordinates(p: Vector3) -> void:
	if _label == null:
		return
	var t := ""
	if axis == "xyz":
		t = "x = %.2f\ny = %.2f\nz = %.2f" % [p.x, p.y, p.z]
	else:
		var v: float = p.x
		if axis == "y":
			v = p.y
		elif axis == "z":
			v = p.z
		t = "%s = %.2f" % [axis, v]
	if _label.text != t:
		_label.text = t


func apply_grid_config(config: Dictionary) -> void:
	if config.has("axis"):
		var a := str(config["axis"]).strip_edges().to_lower()
		if a in ["xyz", "x", "y", "z"]:
			axis = a
			_reset_text()
