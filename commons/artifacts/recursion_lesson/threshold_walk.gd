extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## A second receiver of the square study's actual terms, measured in metres.
## The gaps between frames are authored placement, not recursive output.
var source: Node3D
var sizes: Array[float] = []
var _frames: Node3D

func _ready() -> void:
	source = get_parent().source
	# The desk faces the entrance. Turn this receiver back toward the hall.
	position = Vector3(-4, 0, 1)
	rotation.y = PI
	var caption := label("SAME SIZES / ANOTHER WAY THROUGH", Vector3(0, 0.025, -0.65), 0.00085)
	caption.rotation_degrees = Vector3(-90, 180, 0)
	refresh_terms()

func refresh_terms() -> void:
	var terms: Array[float] = source._terms()
	if terms == sizes: return
	sizes = terms.duplicate()
	if is_instance_valid(_frames):
		remove_child(_frames)
		_frames.queue_free()
	_frames = Node3D.new()
	_frames.name = "Frames"
	add_child(_frames)
	for i in sizes.size():
		var side: float = sizes[i]
		var bar := minf(0.055, side * 0.09)
		var frame := Node3D.new()
		frame.name = "Term%d" % (i + 1)
		frame.position.z = float(i)
		frame.set_meta("side_metres", side)
		frame.set_meta("opening_width", side - 2 * bar)
		frame.set_meta("opening_height", side - bar)
		_frames.add_child(frame)
		var tint := StandardMaterial3D.new()
		tint.albedo_color = source.iteration_colors[i % source.iteration_colors.size()]
		tint.albedo_color.a = 1.0
		tint.roughness = 0.45
		for x in [-1.0, 1.0]:
			box(Vector3(x * (side - bar) * 0.5, side * 0.5, 0), Vector3(bar, side, bar), tint, true, frame)
		box(Vector3(0, side - bar * 0.5, 0), Vector3(side - 2 * bar, bar, bar), tint, true, frame)
		# The floor closes the square. Its inlay has no raised collision sill.
		box(Vector3(0, 0.004, 0), Vector3(side - 2 * bar, 0.008, bar), tint, false, frame)
