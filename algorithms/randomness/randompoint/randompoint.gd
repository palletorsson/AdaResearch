extends Node3D

@export var area_half_extent: float = 0.8  # random within [-0.8, 0.8] on X and Y

var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point_with_color.tscn")
var point_node: Node3D

func _ready():
	randomize()
	_spawn_random_point_xy()

func _spawn_random_point_xy():
	var p := point_scene.instantiate()
	p.name = "RandomPoint"
	add_child(p)
	point_node = p
	var x := randf_range(-area_half_extent, area_half_extent)
	var y := randf_range(-area_half_extent, area_half_extent)
	p.position = Vector3(x, y, 0.0)
	_update_label(p)
	if p.has_signal("dropped"):
		p.connect("dropped", _on_point_dropped)

func _on_point_dropped(_pickable):
	var p: Node3D = _pickable
	var x = clamp(p.position.x, -area_half_extent, area_half_extent)
	var y = clamp(p.position.y, -area_half_extent, area_half_extent)
	p.position = Vector3(x, y, 0.0)
	_update_label(p)

func _update_label(p: Node3D):
	var label: Label3D = p.get_node_or_null("XYLabel")
	if label == null:
		label = Label3D.new()
		label.name = "XYLabel"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.transform.origin = Vector3(0, 0.06, 0)
		p.add_child(label)
	# Set label scale to 0.1
	label.scale = Vector3.ONE * 0.1
	label.text = "(%.2f, %.2f)" % [p.position.x, p.position.y]

func _process(delta):
	if point_node == null:
		return
	var pos := point_node.position
	var clamped := Vector3(
		clamp(pos.x, -area_half_extent, area_half_extent),
		clamp(pos.y, -area_half_extent, area_half_extent),
		0.0
	)
	if clamped != pos:
		point_node.position = clamped
		_update_label(point_node)
