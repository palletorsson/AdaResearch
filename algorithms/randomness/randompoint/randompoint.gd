extends Node3D

# @identity
# essence: point = (randf_range(-e, e), randf_range(-e, e)) — pure white noise in 2D, every position equally likely
# desire: to feel the lottery of position — grab the point, release it, watch it land somewhere that has no memory of where it was
# critical_parameter: area_half_extent — the size of the possible universe this point can inhabit
# triggers: dropping the point resets it; every drop is a new draw from the same distribution
# emerges: the learner begins to notice that no region of space fills up faster than any other — uniformity as a lived sensation
# needs: grab_sphere_point [has]; slider for area_half_extent [missing]; regenerate button [missing]
# relationships: contrasts with randompoints (blue noise enforces spacing); precedes noiselayers (noise adds memory); pairs with randompoints for white vs blue comparison
# truth: white noise is the null hypothesis of space — the universe before it learned to care where things go

@export var area_half_extent: float = 0.8  # random within [-0.8, 0.8] on X and Y

var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point_with_color.tscn")
var point_node: Node3D

func _ready() -> void:
	randomize()
	_spawn_random_point_xy()

func _spawn_random_point_xy() -> void:
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

func _on_point_dropped(_pickable) -> void:
	var p: Node3D = _pickable
	var x = clamp(p.position.x, -area_half_extent, area_half_extent)
	var y = clamp(p.position.y, -area_half_extent, area_half_extent)
	p.position = Vector3(x, y, 0.0)
	_update_label(p)

func _update_label(p: Node3D) -> void:
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

func _process(_delta):
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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
