extends "res://algorithms/vectors/shared/vector_scene_base.gd"

@export var axis_length: float = 1.5

var x_line: Node3D
var y_line: Node3D
var z_line: Node3D
var _axis_labels: Dictionary = {}

func _ready() -> void:
	super._ready()
	_clear_environment()
	_spawn_vectors()
	_refresh_vectors()
	# Static scene - no process loop needed
	set_process(false)

func _spawn_vectors() -> void:
	x_line = _spawn_axis(Vector3.RIGHT, Color.RED, "X")
	y_line = _spawn_axis(Vector3.UP, Color.GREEN, "Y")
	z_line = _spawn_axis(Vector3.BACK, Color.BLUE, "Z")

func _spawn_axis(_direction: Vector3, color: Color, name: String) -> Node3D:
	var line = spawn_vector(Vector3.ZERO, Vector3.ZERO, color, "%s-line" % name, false)
	_hide_vector_builtins(line)
	_ensure_axis_label(name, color)
	return line

func _refresh_vectors() -> void:
	_update_axis(x_line, Vector3.RIGHT, "X")
	_update_axis(y_line, Vector3.UP, "Y")
	_update_axis(z_line, Vector3.BACK, "Z")

func _update_axis(line: Node3D, direction: Vector3, name: String) -> void:
	if line == null:
		return
	var target = direction.normalized() * axis_length
	update_vector(line, target)
	var label: Label3D = _axis_labels.get(name, null)
	if label:
		label.position = target + direction.normalized() * 0.2

func _ensure_axis_label(name: String, color: Color) -> void:
	if _axis_labels.has(name):
		return
	var label = Label3D.new()
	label.name = "%sAxisLabel" % name
	label.text = name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	label.modulate = color
	label.outline_size = 3
	label.outline_modulate = Color(0, 0, 0, 1)
	label.position = Vector3.ZERO
	_axis_labels[name] = label
	if environment_root:
		environment_root.add_child(label)
	else:
		add_child(label)

func _hide_vector_builtins(vector_line: Node3D) -> void:
	if vector_line == null:
		return
	var container := vector_line.get_node_or_null("lineContainer")
	if container == null:
		return
	var length_label: Label3D = container.get_node_or_null("LengthLabel")
	if length_label:
		length_label.visible = false
	for grab_name in ["GrabSphere", "GrabSphere2"]:
		var grab := container.get_node_or_null(grab_name)
		if grab == null:
			continue
		var grab_label: Label3D = grab.get_node_or_null("MeshInstance3D/Label3D")
		if grab_label:
			grab_label.visible = false

func _clear_environment() -> void:
	if environment_root:
		for child in environment_root.get_children():
			child.queue_free()
	if info_root:
		for child in info_root.get_children():
			child.queue_free()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
